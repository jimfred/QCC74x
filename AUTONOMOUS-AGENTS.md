# Autonomous Build Agents - Self-Healing CI/CD

True autonomous development agents that **detect build failures and automatically fix them** without human intervention.

## 🎯 Three Levels of Autonomy

| Level | Agent | Capabilities | When to Use |
|-------|-------|--------------|-------------|
| **Level 1** | Basic Monitor | Reports failures | Quick status checks |
| **Level 2** | Rule-Based Agent | Applies predefined fixes | Common build errors |
| **Level 3** | AI-Powered Agent | Intelligent analysis & fixes | Complex issues |

---

## 🤖 Level 1: Basic Monitor

**File:** `scripts/monitor-build.sh`

### What It Does
- Attempts build
- Reports success/failure
- Sends notifications
- **Does NOT fix errors**

### Usage
```bash
./scripts/monitor-build.sh "https://discord.com/api/webhooks/YOUR_WEBHOOK"
```

**Best for:** Quick status checks, monitoring existing stable builds

---

## 🔧 Level 2: Rule-Based Autonomous Agent

**File:** `scripts/autonomous-build-agent.sh`

### What It Does
✅ Attempts build
✅ Detects error patterns
✅ Applies automatic fixes:
  - Missing board definitions → Creates minimal board files
  - Device tree errors → Simplifies overlay
  - CMake errors → Fixes configuration
  - Missing dependencies → Installs packages
  - Environment issues → Sets up Zephyr

✅ Commits fixes
✅ Retries build
✅ Repeats up to N iterations

### Usage

```bash
# Local execution
./scripts/autonomous-build-agent.sh 5 "https://discord.com/api/webhooks/YOUR_WEBHOOK"
#                                    ^
#                                    max iterations
```

### In GitHub Actions

Automatically runs on push to `claude/**` or `autonomous/**` branches:

```yaml
# .github/workflows/autonomous-fix.yml
# Triggered automatically on push
```

### What Gets Fixed Automatically

1. **Board Not Found**
   ```
   Error: Board qcc748m not found
   → Creates minimal board definition files
   → Retries build
   ```

2. **Device Tree Errors**
   ```
   Error: DTS parsing failed
   → Simplifies overlay to minimal config
   → Retries build
   ```

3. **CMake Configuration Issues**
   ```
   CMake Error at CMakeLists.txt:5
   → Updates CMake to be more permissive
   → Cleans build directory
   → Retries build
   ```

4. **Missing Dependencies**
   ```
   Error: device-tree-compiler: command not found
   → Runs apt-get install
   → Retries build
   ```

5. **Environment Not Set**
   ```
   Error: ZEPHYR_BASE not set
   → Sources zephyr-env.sh
   → Sets environment variables
   → Retries build
   ```

### Example Autonomous Session

```bash
$ ./scripts/autonomous-build-agent.sh 5

🤖 Autonomous Build Agent starting...
📋 Log: /tmp/autonomous-agent-20241212-103045.log
🔄 Max iterations: 5

--- Iteration 1/5 ---
🔨 Attempting build...
❌ Build failed
🔍 Analyzing build errors...
📋 Detected: Board not found - attempting to create board definition
✅ Board definition created

--- Iteration 2/5 ---
🔨 Attempting build...
❌ Build failed
🔍 Analyzing build errors...
🌳 Detected: Device tree error - attempting to simplify overlay
✅ Device tree overlay simplified

--- Iteration 3/5 ---
🔨 Attempting build...
✅ Build succeeded!
🎉 Build successful on iteration 3!
📦 Binary size: 42K
```

**Result:** Build fixed automatically, changes committed, you get a notification!

---

## 🧠 Level 3: AI-Powered Autonomous Agent

**File:** `scripts/ai-powered-build-agent.py`

### What It Does

✅ Everything Level 2 does, PLUS:
✅ **Analyzes errors with AI** (Claude, GPT)
✅ **Generates custom fixes** for unique errors
✅ **Understands project context**
✅ **Learns from your codebase**
✅ **Explains what it's doing**

### Setup

1. **Get an API key:**
   - Anthropic Claude: https://console.anthropic.com/
   - OpenAI GPT: https://platform.openai.com/

2. **Set environment variable:**
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-your-key-here"
   # or
   export OPENAI_API_KEY="sk-your-key-here"
   ```

3. **Install dependencies:**
   ```bash
   pip3 install requests
   ```

### Usage

```bash
# With API key in environment
export ANTHROPIC_API_KEY="sk-ant-..."
export WEBHOOK_URL="https://discord.com/api/webhooks/..."

python3 scripts/ai-powered-build-agent.py --max-iterations 5

# Or specify inline
python3 scripts/ai-powered-build-agent.py \
    --api-key "sk-ant-..." \
    --webhook "https://discord.com/..." \
    --max-iterations 5
```

### How It Works

1. **Attempts build** → Fails with errors
2. **Reads your project files** (CMakeLists.txt, source code, configs)
3. **Sends error + context to AI:**
   ```
   "I have these errors: [errors]
    In this project: [your code]
    How do I fix it?"
   ```
4. **AI analyzes** and responds with JSON:
   ```json
   {
     "explanation": "The issue is that GPIO controller name is wrong...",
     "fixes": [
       {
         "file": "boards/qcc748m.overlay",
         "action": "modify",
         "content": "/ { gpio0: gpio@... }"
       }
     ]
   }
   ```
5. **Applies fixes** automatically
6. **Commits** with AI's explanation
7. **Retries build**
8. **Repeats** until success or max iterations

### Example AI-Powered Session

```bash
$ python3 scripts/ai-powered-build-agent.py --max-iterations 5

🤖 AI-Powered Build Agent starting...
📋 Log: /tmp/ai-build-agent-20241212-104523.log
🔄 Max iterations: 5

--- Iteration 1/5 ---
🔨 Attempting build...
❌ Build failed
🤖 Consulting AI for fix suggestions...
✅ AI provided 2 fix suggestions
💡 AI: The GPIO controller in your device tree overlay has an incorrect node reference.
       The 'gpios' property should reference '&gpio' not '&gpio0' as that node doesn't
       exist in your base device tree.
🔧 Applying 2 AI-suggested fixes...
  ✅ modify: boards/qcc748m.overlay
  ✅ modify: prj.conf
📝 Committing fixes...
✅ Fixes committed

--- Iteration 2/5 ---
🔨 Attempting build...
✅ Build successful!
🎉 Build successful on iteration 2!
```

**The AI understood the problem, fixed it intelligently, and explained it!**

---

## 📱 Autonomous Workflow: Kick-Off and Monitor from Phone

### Complete Example

**Morning (from laptop):**
```bash
# Make some changes
vim zephyr-gpio-blinky/src/main.c

# Commit and push
git add .
git commit -m "Add new feature"
git push origin autonomous/my-feature

# GitHub Actions automatically:
# 1. Detects push
# 2. Runs autonomous-build-agent
# 3. Fixes any errors
# 4. Commits fixes
# 5. Sends notification

# You get Discord notification: "✅ Build successful after 2 iterations"
```

**Afternoon (from phone):**
- Open Discord app
- See: "✅ Build successful!"
- Click GitHub link
- Review changes agent made
- Merge PR if happy

**You never had to debug the build errors - the agent did it autonomously!**

---

## 🚀 GitHub Actions Integration

### Automatic on Every Push

The workflow `.github/workflows/autonomous-fix.yml` runs automatically when you push to:
- `claude/**` branches
- `autonomous/**` branches

### What Happens

1. **Push code** (even if it has build errors)
2. **GitHub Actions starts** autonomous agent
3. **Agent tries to build** → Fails
4. **Agent analyzes errors**
5. **Agent applies fixes**
6. **Agent commits fixes** to your branch
7. **Agent retries build** → Success!
8. **You get notification** on phone
9. **Agent posts comment** on PR with summary

### View Results

- **GitHub Mobile App** → Actions tab → See agent logs
- **Workflow Summary** → Shows what was fixed
- **Commit History** → See agent's fix commits
- **Artifacts** → Download full logs

---

## 🔔 Notification Setup

### Discord (Recommended)

1. **Create webhook:**
   - Discord Server → Channel Settings
   - Integrations → Webhooks → New Webhook
   - Copy URL

2. **Use it:**
   ```bash
   export WEBHOOK_URL="https://discord.com/api/webhooks/123/abc"
   ./scripts/autonomous-build-agent.sh 5 "$WEBHOOK_URL"
   ```

3. **Get notifications:**
   - 🔨 Build starting
   - 🔧 Applying fix
   - ✅ Build successful
   - ❌ Build failed

### Slack

Same process, use Slack incoming webhook URL

### Telegram

Create a bot and use bot API:
```bash
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
     -d "chat_id=<CHAT_ID>" \
     -d "text=Build successful!"
```

---

## 🎛️ Configuration

### Max Iterations

Control how many times agent tries to fix:

```bash
# Shell script
./scripts/autonomous-build-agent.sh 10  # Try 10 times

# Python script
python3 scripts/ai-powered-build-agent.py --max-iterations 10
```

### Webhook

```bash
# Via environment variable
export WEBHOOK_URL="https://discord.com/..."

# Or pass inline
./scripts/autonomous-build-agent.sh 5 "https://discord.com/..."
```

### AI Model

Edit `scripts/ai-powered-build-agent.py`:

```python
# Change model
payload = {
    "model": "claude-3-opus-20240229",  # More powerful
    # or "claude-3-haiku-20240307"      # Faster, cheaper
}
```

---

## 📊 Monitoring & Logs

### View Logs

**Local:**
```bash
tail -f /tmp/autonomous-agent-*.log
tail -f /tmp/ai-build-agent-*.log
```

**GitHub Actions:**
- Actions tab → Select workflow run
- View job logs
- Download artifacts (full logs)

### Logs Include

- Each iteration attempt
- Errors detected
- Fixes applied
- AI explanations (for AI agent)
- Build output
- File changes

---

## 🔐 Security Considerations

### API Keys

**NEVER commit API keys to git!**

✅ **Good:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
python3 scripts/ai-powered-build-agent.py
```

❌ **Bad:**
```bash
# Don't hardcode in scripts!
api_key = "sk-ant-api-key-here"
```

### GitHub Actions Secrets

Store API keys as repository secrets:

1. GitHub → Settings → Secrets and variables → Actions
2. New repository secret
3. Name: `ANTHROPIC_API_KEY`
4. Value: `sk-ant-your-key`

Use in workflow:
```yaml
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Webhook URLs

Less sensitive, but still use secrets:
```yaml
env:
  WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK }}
```

---

## 🛠️ Troubleshooting

### Agent Keeps Failing

**Check logs:**
```bash
cat /tmp/autonomous-agent-*.log
```

**Common issues:**
1. Max iterations too low → Increase
2. Missing sudo → Run in environment with sudo
3. Zephyr not installed → Install Zephyr first
4. API quota exceeded → Check API usage

### AI Agent Not Calling API

**Verify:**
```bash
# Check API key is set
echo $ANTHROPIC_API_KEY

# Test API manually
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-sonnet-20240229","messages":[{"role":"user","content":"test"}],"max_tokens":100}'
```

### Notifications Not Working

**Test webhook:**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"content": "Test message"}'
```

### GitHub Actions Not Running

**Check:**
1. Workflow file syntax (YAML valid?)
2. Branch name matches trigger pattern
3. Actions enabled in repo settings
4. Check Actions tab for error messages

---

## 📈 Success Metrics

Track agent performance:

```bash
# View agent statistics
grep "successful on iteration" /tmp/autonomous-agent-*.log

# Common patterns
grep "Detected:" /tmp/autonomous-agent-*.log | sort | uniq -c

# Success rate
total=$(ls -1 /tmp/autonomous-agent-*.log | wc -l)
success=$(grep -l "Build successful" /tmp/autonomous-agent-*.log | wc -l)
echo "Success rate: $((success * 100 / total))%"
```

---

## 🎓 Advanced Usage

### Chain Multiple Agents

```bash
# Level 2 first (fast), then Level 3 if needed
if ! ./scripts/autonomous-build-agent.sh 3; then
    echo "Rule-based agent failed, trying AI agent..."
    python3 scripts/ai-powered-build-agent.py --max-iterations 5
fi
```

### Custom Fix Rules

Edit `scripts/autonomous-build-agent.sh`:

```bash
# Add your own fix pattern
if echo "$error_context" | grep -q "YOUR_CUSTOM_ERROR"; then
    notify "🔧 Custom fix for YOUR_CUSTOM_ERROR" "FIX"
    # Your fix logic here
    return 0
fi
```

### Pre-commit Hook

Run agent before allowing commits:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/autonomous-build-agent.sh 2 || {
    echo "Auto-fix failed, please fix manually"
    exit 1
}
```

---

## 🎯 Comparison Table

| Feature | Monitor | Rule-Based | AI-Powered |
|---------|---------|------------|------------|
| Detects failures | ✅ | ✅ | ✅ |
| Sends notifications | ✅ | ✅ | ✅ |
| Applies fixes | ❌ | ✅ | ✅ |
| Handles common errors | ❌ | ✅ | ✅ |
| Handles unique errors | ❌ | ❌ | ✅ |
| Explains fixes | ❌ | ❌ | ✅ |
| Learns from context | ❌ | ❌ | ✅ |
| Requires API key | ❌ | ❌ | ✅ |
| Cost | Free | Free | ~$0.01-0.10/build |
| Speed | Fast | Fast | Slower (API calls) |

---

## 🚀 Quick Start Checklist

**Level 2 (Rule-Based) - 5 minutes:**
- [ ] Push to `claude/**` or `autonomous/**` branch
- [ ] GitHub Actions runs automatically
- [ ] Check phone for notification
- [ ] Done!

**Level 3 (AI-Powered) - 15 minutes:**
- [ ] Get Anthropic API key
- [ ] Set `ANTHROPIC_API_KEY` environment variable
- [ ] Add as GitHub Actions secret
- [ ] Run locally or push to trigger Actions
- [ ] Watch AI intelligently fix your build!

---

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Anthropic Claude API](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [OpenAI API](https://platform.openai.com/docs)
- [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)
- [Zephyr RTOS Docs](https://docs.zephyrproject.org/)

---

## 🎉 Summary

You now have **three levels of autonomous build agents**:

1. **Monitor** - Passive observation
2. **Rule-Based** - Automatic fixes for common errors
3. **AI-Powered** - Intelligent analysis and custom fixes

**All integrated with:**
- ✅ GitHub Actions (auto-run on push)
- ✅ Mobile notifications (Discord/Slack)
- ✅ Automatic commits
- ✅ PR comments
- ✅ Full logging

**Your builds can fix themselves while you sleep!** 🌙

---

Happy autonomous developing! 🤖🚀
