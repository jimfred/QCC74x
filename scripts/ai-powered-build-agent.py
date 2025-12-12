#!/usr/bin/env python3
"""
AI-Powered Autonomous Build Agent

This script uses an AI API (Claude, GPT, etc.) to intelligently analyze
build errors and propose fixes. It can run autonomously and make commits.

Usage:
    python3 ai-powered-build-agent.py [--api-key KEY] [--max-iterations 5]

Environment variables:
    ANTHROPIC_API_KEY or OPENAI_API_KEY: API key for AI service
    WEBHOOK_URL: Discord/Slack webhook for notifications
"""

import os
import sys
import subprocess
import argparse
import json
import time
from datetime import datetime
from pathlib import Path
import re

try:
    import requests
except ImportError:
    print("Installing requests...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests"])
    import requests


class BuildAgent:
    def __init__(self, project_dir, max_iterations=5, webhook_url=None, api_key=None):
        self.project_dir = Path(project_dir)
        self.max_iterations = max_iterations
        self.webhook_url = webhook_url
        self.api_key = api_key or os.getenv('ANTHROPIC_API_KEY') or os.getenv('OPENAI_API_KEY')
        self.log_file = Path(f"/tmp/ai-build-agent-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log")
        self.iteration = 0

    def log(self, message, level="INFO"):
        """Log message to file and console"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_line = f"[{timestamp}] [{level}] {message}"

        print(log_line)

        with open(self.log_file, 'a') as f:
            f.write(log_line + '\n')

        self.notify(message, level)

    def notify(self, message, level="INFO"):
        """Send notification via webhook"""
        if not self.webhook_url:
            return

        emoji_map = {
            "INFO": "ℹ️",
            "SUCCESS": "✅",
            "ERROR": "❌",
            "WARNING": "⚠️",
            "BUILD": "🔨",
            "FIX": "🔧",
            "AI": "🤖"
        }

        emoji = emoji_map.get(level, "📝")

        payload = {
            "content": f"{emoji} **Iteration {self.iteration}** - [{level}] {message}"
        }

        try:
            requests.post(self.webhook_url, json=payload, timeout=5)
        except Exception:
            pass

    def run_command(self, cmd, cwd=None, capture=True):
        """Run shell command and return output"""
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                cwd=cwd or self.project_dir,
                capture_output=capture,
                text=True,
                timeout=300
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as e:
            return -1, "", str(e)

    def attempt_build(self):
        """Attempt to build the project"""
        self.log(f"🔨 Attempting build (iteration {self.iteration}/{self.max_iterations})...", "BUILD")

        build_dir = self.project_dir / "zephyr-gpio-blinky"

        # Try west build first
        if os.getenv('ZEPHYR_BASE'):
            cmd = "west build -b qcc748m -p auto"
            returncode, stdout, stderr = self.run_command(cmd, cwd=build_dir)

            if returncode == 0:
                self.log("✅ Build successful!", "SUCCESS")
                return True, None

            error_output = stdout + stderr
        else:
            # Fallback to CMake
            cmd = "cmake -B build -GNinja && ninja -C build"
            returncode, stdout, stderr = self.run_command(cmd, cwd=build_dir)

            if returncode == 0:
                self.log("✅ Build successful!", "SUCCESS")
                return True, None

            error_output = stdout + stderr

        self.log("❌ Build failed", "ERROR")

        # Extract relevant error information
        errors = self.extract_errors(error_output)

        return False, errors

    def extract_errors(self, output):
        """Extract key error messages from build output"""
        error_patterns = [
            r"error:.*",
            r"Error:.*",
            r"ERROR:.*",
            r"CMake Error.*",
            r"fatal error:.*",
            r"undefined reference.*",
            r"No such file or directory.*",
            r"Board .* not found.*"
        ]

        errors = []
        for line in output.split('\n'):
            for pattern in error_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    errors.append(line.strip())

        # Return unique errors, limit to 20
        return list(set(errors))[:20]

    def ask_ai_for_fix(self, errors):
        """Use AI to analyze errors and suggest fixes"""
        if not self.api_key:
            self.log("⚠️ No API key provided, skipping AI analysis", "WARNING")
            return None

        self.log("🤖 Consulting AI for fix suggestions...", "AI")

        # Read current project files
        context = self.gather_project_context()

        prompt = f"""I'm trying to build a Zephyr RTOS project and encountering errors.

Project context:
{context}

Build errors:
{chr(10).join(errors[:10])}

Please analyze these errors and provide:
1. A brief explanation of what's wrong
2. Specific file changes needed to fix the issue (as a JSON array)

Format your response as JSON:
{{
    "explanation": "...",
    "fixes": [
        {{
            "file": "path/to/file",
            "action": "create|modify|delete",
            "content": "new file content or modification"
        }}
    ]
}}
"""

        try:
            # Try Anthropic Claude API
            if 'anthropic' in self.api_key.lower() or 'sk-ant' in self.api_key:
                response = self.call_anthropic_api(prompt)
            else:
                response = self.call_openai_api(prompt)

            if response:
                self.log(f"✅ AI provided {len(response.get('fixes', []))} fix suggestions", "AI")
                return response

        except Exception as e:
            self.log(f"❌ AI API call failed: {str(e)}", "ERROR")

        return None

    def call_anthropic_api(self, prompt):
        """Call Anthropic Claude API"""
        url = "https://api.anthropic.com/v1/messages"

        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }

        payload = {
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 4096,
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }

        response = requests.post(url, headers=headers, json=payload, timeout=60)
        response.raise_for_status()

        content = response.json()['content'][0]['text']

        # Extract JSON from response
        json_match = re.search(r'\{[\s\S]*\}', content)
        if json_match:
            return json.loads(json_match.group())

        return None

    def call_openai_api(self, prompt):
        """Call OpenAI GPT API"""
        url = "https://api.openai.com/v1/chat/completions"

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": "gpt-4",
            "messages": [
                {"role": "system", "content": "You are a helpful build system expert. Always respond with valid JSON."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7
        }

        response = requests.post(url, headers=headers, json=payload, timeout=60)
        response.raise_for_status()

        content = response.json()['choices'][0]['message']['content']

        # Extract JSON from response
        json_match = re.search(r'\{[\s\S]*\}', content)
        if json_match:
            return json.loads(json_match.group())

        return None

    def gather_project_context(self):
        """Gather relevant project files for AI context"""
        context_files = [
            "zephyr-gpio-blinky/CMakeLists.txt",
            "zephyr-gpio-blinky/prj.conf",
            "zephyr-gpio-blinky/boards/qcc748m.overlay",
            "zephyr-gpio-blinky/src/main.c"
        ]

        context = ""
        for file_path in context_files:
            full_path = self.project_dir / file_path
            if full_path.exists():
                context += f"\n--- {file_path} ---\n"
                try:
                    context += full_path.read_text()[:1000]  # Limit size
                except Exception:
                    context += "(unable to read)\n"

        return context

    def apply_fixes(self, fixes):
        """Apply AI-suggested fixes to files"""
        if not fixes:
            return False

        self.log(f"🔧 Applying {len(fixes)} AI-suggested fixes...", "FIX")

        for fix in fixes:
            file_path = self.project_dir / fix['file']
            action = fix['action']
            content = fix.get('content', '')

            try:
                if action == 'create' or action == 'modify':
                    file_path.parent.mkdir(parents=True, exist_ok=True)
                    file_path.write_text(content)
                    self.log(f"  ✅ {action}: {fix['file']}", "FIX")

                elif action == 'delete':
                    if file_path.exists():
                        file_path.unlink()
                        self.log(f"  ✅ deleted: {fix['file']}", "FIX")

            except Exception as e:
                self.log(f"  ❌ Failed to {action} {fix['file']}: {str(e)}", "ERROR")
                return False

        return True

    def commit_fixes(self, explanation):
        """Commit applied fixes to git"""
        self.log("📝 Committing fixes...", "INFO")

        self.run_command('git config user.name "AI Build Agent"')
        self.run_command('git config user.email "ai-agent@localhost"')
        self.run_command('git add .')

        commit_msg = f"""🤖 AI-powered fix (iteration {self.iteration})

{explanation}

Auto-generated by AI build agent
"""

        self.run_command(f'git commit -m "{commit_msg}"')
        self.log("✅ Fixes committed", "SUCCESS")

    def run(self):
        """Main autonomous loop"""
        self.log("🤖 AI-Powered Build Agent starting...", "INFO")
        self.log(f"📋 Log file: {self.log_file}", "INFO")
        self.log(f"🔄 Max iterations: {self.max_iterations}", "INFO")

        while self.iteration < self.max_iterations:
            self.iteration += 1

            self.log(f"--- Iteration {self.iteration}/{self.max_iterations} ---", "INFO")

            # Attempt build
            success, errors = self.attempt_build()

            if success:
                self.log(f"🎉 Build successful on iteration {self.iteration}!", "SUCCESS")
                return True

            # No errors extracted, can't proceed
            if not errors:
                self.log("⚠️ Build failed but no errors extracted", "WARNING")
                continue

            # Ask AI for fix
            ai_response = self.ask_ai_for_fix(errors)

            if not ai_response:
                self.log("⚠️ No AI fix suggestions available", "WARNING")
                continue

            # Log AI explanation
            self.log(f"💡 AI: {ai_response.get('explanation', 'No explanation')}", "AI")

            # Apply fixes
            if self.apply_fixes(ai_response.get('fixes', [])):
                self.commit_fixes(ai_response.get('explanation', 'Auto-fix'))
            else:
                self.log("❌ Failed to apply some fixes", "ERROR")

            time.sleep(2)

        self.log(f"❌ Failed to build after {self.max_iterations} iterations", "ERROR")
        self.log(f"📄 Review log: {self.log_file}", "INFO")

        return False


def main():
    parser = argparse.ArgumentParser(description='AI-Powered Autonomous Build Agent')
    parser.add_argument('--project-dir', default='.', help='Project directory')
    parser.add_argument('--max-iterations', type=int, default=5, help='Maximum fix iterations')
    parser.add_argument('--api-key', help='AI API key (or set ANTHROPIC_API_KEY/OPENAI_API_KEY)')
    parser.add_argument('--webhook', help='Webhook URL for notifications')

    args = parser.parse_args()

    # Get webhook from env if not provided
    webhook = args.webhook or os.getenv('WEBHOOK_URL')

    agent = BuildAgent(
        project_dir=args.project_dir,
        max_iterations=args.max_iterations,
        webhook_url=webhook,
        api_key=args.api_key
    )

    success = agent.run()

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
