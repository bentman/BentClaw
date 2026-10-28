# 🏛️ Hermes Setup Guide

Post-deploy steps for the Azure VM. Replace `<placeholders>` with your values.
For the Docker variant see [docker/README.md](docker/README.md).

## 1. Rebuild the VM (optional)

```bash
terraform plan -replace='azurerm_linux_virtual_machine.openclaw' -replace='azurerm_storage_account.hermes_backup'
terraform apply -replace='azurerm_linux_virtual_machine.openclaw' -replace='azurerm_storage_account.hermes_backup'
terraform output next_steps
```

## 2. Connect

```bash
ssh -i ~/.ssh/<key>.pem <user>@<vm_fqdn>
```

Tunnel the gateway, dashboard, and optional extra ports to your machine:

```bash
ssh -i ~/.ssh/<key>.pem \
  -L 8643:127.0.0.1:8642 \
  -L 9120:127.0.0.1:9119 \
  -L 18790:127.0.0.1:18789 \
  <user>@<vm_fqdn>
```

Copy a file to the VM (for example an avatar):

```bash
scp -i ~/.ssh/<key>.pem <local_file> <user>@<vm_fqdn>:/home/<user>/<file>
```

## 3. Wait for cloud-init

On the VM, after a rebuild:

```bash
cloud-init status --wait
```

## 4. Log in to tools

```bash
pushd WORK/CODE/REPO
az login --use-device-code
claude auth login
codex login --device-auth
agy
popd
```

## 5. Configure git and GitHub

```bash
git config --global user.name <name>
git config --global user.email <email>
gh auth login
```

## 6. Set up Hermes

```bash
# verify install
hermes --version
hermes doctor

# interactive setup wizard (provider, model, tools)
hermes setup

# or fast-track via Nous Portal OAuth
hermes setup --portal
```

## 7. Install the gateway service

```bash
# interactive channel config (Discord, Telegram, Slack, etc.)
hermes gateway setup

# register as systemd background service
hermes gateway install
hermes gateway start
hermes gateway status
```

## 8. Launch the dashboard (headless)

On the VM, `--no-open` prevents `xdg-open` from trying to launch a browser:

```bash
hermes dashboard --host 0.0.0.0 --port 9119 --no-open
```

With the tunnel from step 2 running, open <http://127.0.0.1:9120> on your local machine.

### Dashboard basic auth (required for non-loopback)

Add to `~/.hermes/.env`:

```ini
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=YourStrongPasswordHere
HERMES_DASHBOARD_BASIC_AUTH_SECRET=random_32byte_secret_here
```

## 9. API server (OpenAI-compatible)

Exposes `http://<host>:8642/v1/chat/completions` with full tool calling, memory, and skills.

Add to `~/.hermes/.env`:

```ini
API_SERVER_ENABLED=true
API_SERVER_KEY=sk-hermes-your-secret-key
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
```

Restart the gateway to pick up changes: `hermes gateway restart`

## 10. Personalize the agent (optional)

```bash
hermes setup agent
```

Or inside a REPL session (`hermes`), send a message like:

```text
I will call you `<name>`.
Use `<emoji>` for emoji and `/home/<user>/<avatar>.png` for avatar.
Vibe: `<one-line personality>`.
```

## Quick reference

| Command | What it does |
|---|---|
| `hermes` | Interactive REPL |
| `hermes chat -q "..."` | One-shot query |
| `hermes doctor` | Health check |
| `hermes doctor --fix` | Auto-repair config issues |
| `hermes model` | Switch provider/model |
| `hermes gateway status` | Gateway health |
| `hermes memory status` | Memory backend status |
| `hermes skills list` | Installed skills |
| `hermes claw migrate` | Import from OpenClaw |

## OpenClaw (optional)

OpenClaw is disabled by default. To enable, uncomment the install line in `cloud-init.yaml` and rebuild the VM. See [Guide_OpenClaw.md](Guide_OpenClaw.md).
