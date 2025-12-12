#!/bin/bash
# Autonomous build monitor with notifications
# Usage: ./monitor-build.sh [webhook_url]

set -e

WEBHOOK_URL="${1:-}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/tmp/qcc74x-build-$(date +%Y%m%d-%H%M%S).log"

notify() {
    local message="$1"
    local status="${2:-info}"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$status] $message" | tee -a "$LOG_FILE"

    # Send to webhook if provided (Discord, Slack, etc.)
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d "{\"content\": \"[$status] $message\"}" \
             2>/dev/null || true
    fi
}

build_project() {
    notify "🚀 Starting autonomous build process" "START"

    cd "$PROJECT_DIR/zephyr-gpio-blinky"

    if [ ! -d "$HOME/zephyrproject" ]; then
        notify "⚠️ Zephyr not found, skipping build" "WARNING"
        return 1
    fi

    export ZEPHYR_BASE="$HOME/zephyrproject/zephyr"

    notify "🔨 Building Zephyr GPIO blinky..." "BUILD"

    if west build -b qcc748m -p auto 2>&1 | tee -a "$LOG_FILE"; then
        notify "✅ Build successful!" "SUCCESS"

        if [ -f "build/zephyr/zephyr.bin" ]; then
            SIZE=$(du -h build/zephyr/zephyr.bin | cut -f1)
            notify "📦 Binary size: $SIZE" "INFO"
        fi

        return 0
    else
        notify "❌ Build failed! Check log: $LOG_FILE" "ERROR"
        return 1
    fi
}

# Main execution
notify "📱 Monitor script started (PID: $$)" "INFO"
notify "📋 Log file: $LOG_FILE" "INFO"

if build_project; then
    notify "🎉 All tasks completed successfully!" "COMPLETE"
    exit 0
else
    notify "⚠️ Some tasks failed" "FAILED"
    exit 1
fi
