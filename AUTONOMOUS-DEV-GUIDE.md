# Autonomous Development Workflow Guide

Monitor and run development tasks remotely from your phone or laptop using GitHub Codespaces, Actions, and notification systems.

## 🎯 Overview

This guide covers three autonomous development approaches:

1. **GitHub Actions** - Automated builds on every push
2. **GitHub Codespaces** - Cloud development environment
3. **Notification System** - Real-time updates to phone/laptop

---

## 📱 Option 1: GitHub Actions (Fully Autonomous)

### What It Does
- Automatically builds on every push to `claude/**` branches
- Runs tests and validation
- Uploads build artifacts
- Sends notifications via GitHub

### Setup

1. **The workflow is already configured** at `.github/workflows/zephyr-build.yml`

2. **Enable GitHub Actions notifications on your phone:**
   - Install **GitHub Mobile App** (iOS/Android)
   - Settings → Notifications → Actions
   - Enable "Workflow runs"

3. **Trigger a build:**
   ```bash
   git push origin claude/your-branch-name
   ```

4. **Monitor from anywhere:**
   - **Phone**: GitHub app → Actions tab
   - **Laptop**: `https://github.com/jimfred/QCC74x/actions`

### Get Email/SMS Notifications

Add to your workflow (after the build step):

```yaml
- name: Send email notification
  uses: dawidd6/action-send-mail@v3
  if: always()
  with:
    server_address: smtp.gmail.com
    server_port: 587
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: "Build ${{ job.status }}: ${{ github.sha }}"
    to: your-email@example.com
    from: GitHub Actions
    body: "Build completed with status: ${{ job.status }}"
```

---

## ☁️ Option 2: GitHub Codespaces (Remote Development)

### What It Does
- Full Linux development environment in the cloud
- Accessible from any browser (phone/laptop)
- Persistent workspace
- Pre-configured with all tools

### Setup

1. **Go to your GitHub repository**
   - Click "Code" → "Codespaces" → "Create codespace on main"

2. **Wait for setup** (2-5 minutes first time)
   - The `.devcontainer` configuration will automatically install dependencies

3. **Access from anywhere:**
   - **Laptop**: Browser at `https://github.com/codespaces`
   - **Phone**: GitHub Mobile app → "Codespaces"
   - **VS Code Desktop**: Install "GitHub Codespaces" extension

### Usage

Once in Codespaces:

```bash
# Setup Zephyr (one-time)
west init ~/zephyrproject
cd ~/zephyrproject
west update
west zephyr-export

# Build your project
cd /workspaces/QCC74x/zephyr-gpio-blinky
west build -b qcc748m -p auto

# Start a long-running task and disconnect
nohup ./scripts/monitor-build.sh > /tmp/build.log 2>&1 &

# Check back later
tail -f /tmp/build.log
```

**Key Feature**: Codespace persists even if you close your browser. Reconnect anytime!

---

## 🔔 Option 3: Real-Time Notifications

### Discord Webhook (Recommended for Phone)

1. **Create Discord webhook:**
   - Discord Server → Edit Channel → Integrations → Webhooks
   - Copy webhook URL

2. **Run autonomous build with notifications:**
   ```bash
   # In Codespaces or any Linux environment
   ./scripts/monitor-build.sh "https://discord.com/api/webhooks/YOUR_WEBHOOK"
   ```

3. **Monitor on your phone:**
   - Open Discord app
   - Receive real-time build notifications

### Slack Webhook

```bash
# Create incoming webhook at: https://api.slack.com/messaging/webhooks
./scripts/monitor-build.sh "https://hooks.slack.com/services/YOUR_WEBHOOK"
```

### Telegram Bot

Create `scripts/notify-telegram.sh`:

```bash
#!/bin/bash
BOT_TOKEN="your_bot_token"
CHAT_ID="your_chat_id"
MESSAGE="$1"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
     -d chat_id="${CHAT_ID}" \
     -d text="${MESSAGE}"
```

---

## 🚀 Complete Autonomous Workflow

### Scenario: Kick off work, monitor from phone

**Step 1: Start work in Codespaces**
```bash
# Open Codespaces from GitHub mobile or web
# Run autonomous build
./scripts/monitor-build.sh "YOUR_DISCORD_WEBHOOK" &
```

**Step 2: Close laptop/phone - work continues**
- Codespace keeps running
- Build executes in background

**Step 3: Receive notification on phone**
- Discord/Slack/Telegram alert when complete

**Step 4: Check results anytime**
```bash
# Reconnect to Codespace
tail -f /tmp/qcc74x-build-*.log
```

---

## 📊 Advanced: Scheduled Builds

Run builds automatically every night:

`.github/workflows/nightly-build.yml`:
```yaml
name: Nightly Build

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
  workflow_dispatch:     # Manual trigger

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build all projects
        run: |
          # Your build commands
          echo "Building all projects..."
      - name: Report results
        run: |
          # Send to monitoring service
```

---

## 🔍 Monitoring Dashboard

### GitHub Actions Dashboard

View all workflow runs:
```
https://github.com/jimfred/QCC74x/actions
```

### Build Status Badge

Add to your README.md:
```markdown
![Build Status](https://github.com/jimfred/QCC74x/workflows/Zephyr%20Build%20&%20Test/badge.svg)
```

---

## 📱 Best Practices for Mobile Monitoring

### 1. Use GitHub Mobile App
- Install from App Store/Play Store
- Enable push notifications for Actions

### 2. Set up webhooks for critical events
- Discord for team collaboration
- Telegram for personal notifications
- Email for important milestones

### 3. Use Codespaces for quick checks
- GitHub mobile app has built-in Codespaces support
- View files, terminal output, logs

### 4. Keep build logs accessible
- Upload artifacts in GitHub Actions
- Store logs in accessible locations

---

## 🛠️ Troubleshooting

### Codespace keeps stopping

**Solution**: Codespaces auto-stop after 30 min of inactivity. To keep alive:

```bash
# Run a keep-alive loop
while true; do echo "alive: $(date)"; sleep 600; done &
```

Or increase timeout:
- GitHub Settings → Codespaces → Default idle timeout

### Notifications not working

**Check webhook URL:**
```bash
# Test Discord webhook
curl -X POST "YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "Test message"}'
```

### Build fails in Actions but works locally

**Common causes:**
- Missing secrets/environment variables
- Different Ubuntu version
- Insufficient permissions

**Debug:**
- Check Actions logs in detail
- Add debug output: `set -x` in scripts
- Run workflow locally with `act`: https://github.com/nektos/act

---

## 🎓 Example: Complete Autonomous Session

```bash
# 1. Start Codespace from GitHub mobile app

# 2. SSH in or use web terminal

# 3. Set up Discord webhook
export WEBHOOK="https://discord.com/api/webhooks/123456/abcdef"

# 4. Run autonomous build
nohup ./scripts/monitor-build.sh "$WEBHOOK" > /tmp/build.log 2>&1 &

# 5. Close everything - build continues

# 6. Get notification on Discord when complete

# 7. Reconnect later to check results
cat /tmp/build.log

# 8. Download artifacts from GitHub Actions
gh run download
```

---

## 🔐 Security Notes

1. **Never commit webhook URLs** - use GitHub Secrets
2. **Use repository secrets** for sensitive data:
   ```yaml
   env:
     WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK }}
   ```
3. **Limit Codespace access** - use private repositories

---

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Codespaces Guide](https://docs.github.com/en/codespaces)
- [GitHub Mobile App](https://github.com/mobile)
- [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)

---

## 🎯 Quick Reference

| Task | Command/Action |
|------|----------------|
| Start Codespace | GitHub → Code → Codespaces → Create |
| View Actions | `https://github.com/jimfred/QCC74x/actions` |
| Trigger build | `git push` to trigger workflow |
| Monitor build | GitHub Mobile app → Actions tab |
| Check logs | Codespace terminal: `tail -f /tmp/*.log` |
| Get artifacts | Actions → Workflow run → Artifacts |

---

Happy autonomous developing! 🚀
