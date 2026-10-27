# BentClaw — OpenClaw Dev-Lab on Linux / WSL

Provisions a Debian/Ubuntu machine or WSL distro like `cloud-init.yaml` does the Azure VM.  
> No OpenVPN — just the toolset, one script, one user.

## What you get

| Item | Details |
|---|---|
| Base | Debian/Ubuntu (apt), including WSL |
| Packages | build tools, git, gh, ffmpeg, python3 + `openai`, Node.js (`node_major`, default 26), azure-cli |
| CLIs | Claude Code, Codex, Antigravity, GitHub Copilot, OpenClaw (no login, no onboarding) |
| User | `openclaw_user`, created with sudo rights if missing |
| Repo | cloned to `~/WORK/CODE/REPO/BentClaw` |
| WSL | user set as the default login |

## Prerequisites

- Debian/Ubuntu or a WSL distro, with `sudo`

## Deploy

```bash
cp linux/.env.example linux/.env
chmod 600 linux/.env          # set openclaw_user and openclaw_pswd
sudo bash linux/.bentclaw.sh
```

`.env` is plain `KEY=value` lines (parsed, never executed):

| Key | Purpose |
|---|---|
| `openclaw_user` | Account that gets the tools |
| `openclaw_pswd` | Password for a new account (ignored if the user exists) |
| `node_major` | Minimum Node.js version |
| `repo_url` | Repo to clone |

Safe to rerun: existing users, installed CLIs and the checkout are left alone.

## Connect

Log in as the configured user. On WSL, apply the new default user first:

```bash
wsl.exe --terminate <distro>
```

## Verify

```bash
openclaw --version
openclaw doctor
```

When ready, finish setup interactively:

```bash
openclaw onboard --install-daemon
```

## Notes

- Not included: OpenVPN (it needs Terraform-rendered values) and WSL systemd.
- Steps run in the same order as `cloud-init.yaml`.
