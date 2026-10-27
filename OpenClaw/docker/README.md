# BentClaw — OpenClaw Dev-Lab in Docker

Runs [OpenClaw](https://docs.openclaw.ai/install/docker) the official way, plus the `cloud-init.yaml` toolset over SSH.  
> No OpenVPN — two containers, localhost-only ports.

## What you get

| Service | Details |
|---|---|
| `openclaw-gateway` | Official `ghcr.io/openclaw/openclaw` image and command (`gateway --bind lan`), 2 CPU / 6 GB |
| `bentclaw` | Same image plus the `cloud-init.yaml` toolset and sshd, 2 CPU / 2 GB |
| Tools | build tools, git, gh, ffmpeg, python3 + `openai`, azure-cli, Claude Code, Codex, Antigravity, GitHub Copilot |
| Repo | cloned to `~/WORK/CODE/REPO/BentClaw` |
| Ports | SSH `127.0.0.1:2222`, Control UI `127.0.0.1:18790` (host's own OpenClaw on 22 / 18789 is unaffected) |
| State | named volumes shared by both services; never the host's `~/.openclaw` |

Node.js and `openclaw` come from the official image, so the Node version is OpenClaw's.

## Prerequisites

- Docker with Compose v2

## Deploy

```bash
cd docker
cp .env.example .env          # set OPENCLAW_GATEWAY_TOKEN and SSH_PUBLIC_KEY (or SSH_PASSWORD)
docker compose up -d --build
```

`openssl rand -hex 32` makes a good token. The tools image is `ghcr.io/bentclaw/bentclaw:latest` (override with `BENTCLAW_IMAGE`).

## Connect

```bash
ssh -p 2222 node@127.0.0.1
```

Open <http://127.0.0.1:18790> and paste the gateway token into Settings. A tunnel works too, as on the VM:

```bash
ssh -p 2222 -L 18791:127.0.0.1:18789 node@127.0.0.1   # then http://127.0.0.1:18791
```

## Verify

```bash
docker compose ps                  # gateway should be healthy
```

Then, over ssh:

```bash
openclaw gateway status --deep
```

First-time setup, same steps as the VM:

```bash
az login --use-device-code
claude auth login
codex login --device-auth
gh auth login
chmod 700 ~/.config
openclaw onboard --no-install-daemon
openclaw config set gateway.controlUi.allowedOrigins '["http://localhost:18790","http://127.0.0.1:18790"]' --strict-json
```

`--no-install-daemon` skips the systemd service; the gateway container is the daemon. Restart it from the host after config changes:

```bash
docker compose restart openclaw-gateway
```

## Cleanup

```bash
docker compose down        # keep state
docker compose down -v     # also delete state, logins and the ssh host key
```

## Notes

- A rebuild does not refresh an existing `home` volume; use `down -v` to reset.
- The `node` user has no sudo, as in the official image.
- azure-cli is installed with pip because the Microsoft apt repo lags new Debian releases.
- Update with `docker compose pull openclaw-gateway`, then rebuild `bentclaw`.
