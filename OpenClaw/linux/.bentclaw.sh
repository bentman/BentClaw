#!/usr/bin/env bash
# BentClaw for Debian/Ubuntu/WSL: the same provisioning as cloud-init.yaml,
# minus OpenVPN. Usage: sudo bash linux/.bentclaw.sh   (reads linux/.env)
set +x                       # never trace; the password is in memory
set -euo pipefail
umask 022

log() { printf '==> %s\n' "$*"; }
die() { printf 'BentClaw: %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die 'run with sudo.'
command -v apt-get >/dev/null || die 'Debian/Ubuntu (apt) is required.'

# ---- config: plain KEY=value lines, parsed (never sourced) -----------------
env_file=$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.env
[[ -f $env_file ]] || die "missing $env_file; copy .env.example to .env and edit it."
openclaw_user=openclaw openclaw_pswd='' node_major=26
repo_url=https://github.com/bentman/BentClaw.git
while IFS='=' read -r key val; do
    val=${val%$'\r'}; val=${val#[\"\']}; val=${val%[\"\']}
    case $key in
        openclaw_user|openclaw_pswd|node_major|repo_url) printf -v "$key" %s "$val" ;;
    esac
done < <(grep -E '^[A-Za-z_]+=' "$env_file")

[[ $openclaw_user =~ ^[a-z_][a-z0-9_-]{0,31}$ && $openclaw_user != root ]] || die 'openclaw_user must be a non-root lowercase username.'
[[ $node_major =~ ^[0-9]+$ ]] || die 'node_major must be a number.'
home=/home/$openclaw_user
run_as() { runuser -l "$openclaw_user" -c "$1"; }    # login shell, like cloud-init

# ---- packages (cloud-init: packages) ---------------------------------------
export DEBIAN_FRONTEND=noninteractive
log 'Installing base packages'
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release \
    openssl build-essential make cmake git g++ gh ffmpeg python3 python3-openai \
    python3-pip sudo

# ---- Node.js (cloud-init: NodeSource) --------------------------------------
if [[ $(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0) -lt $node_major ]]; then
    log "Installing Node.js $node_major"
    curl -fsSL "https://deb.nodesource.com/setup_${node_major}.x" | bash -
    apt-get install -y nodejs
fi
node --version

# ---- Azure CLI (cloud-init: Microsoft apt repo) ----------------------------
if ! command -v az >/dev/null; then
    log 'Installing Azure CLI'
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /etc/apt/keyrings/microsoft.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/azure-cli.list
    apt-get update
    apt-get install -y azure-cli
fi

log 'Upgrading system'
apt-get upgrade -y

# ---- user ------------------------------------------------------------------
if id "$openclaw_user" >/dev/null 2>&1; then
    log "User $openclaw_user exists; password unchanged"
else
    [[ -n $openclaw_pswd && $openclaw_pswd != *:* && $openclaw_pswd != replace-with-* ]] \
        || die 'set a real openclaw_pswd (no colons) in .env to create the user.'
    useradd --create-home --shell /bin/bash "$openclaw_user"
    printf '%s:%s\n' "$openclaw_user" "$openclaw_pswd" | chpasswd
fi
unset openclaw_pswd
usermod -aG sudo "$openclaw_user"

# ---- CLIs (cloud-init: runcmd, same order; each skipped if present) --------
install_cli() {   # <command> <installer pipeline>
    if run_as "command -v $1 >/dev/null"; then log "$1 already installed"; return; fi
    log "Installing $1"
    run_as "$2"
}
install_cli claude   'curl -fsSL https://claude.ai/install.sh | bash -s stable'
install_cli codex    'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'
install_cli agy      'curl -fsSL https://antigravity.google/cli/install.sh | bash'
install_cli copilot  'curl -fsSL https://gh.io/copilot-install | bash'
install_cli openclaw 'curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard'

# ---- PATH and repo ---------------------------------------------------------
run_as 'line='\''export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"'\''; grep -qxF "$line" ~/.bashrc || echo "$line" >> ~/.bashrc'
if [[ ! -d $home/WORK/CODE/REPO/BentClaw ]]; then
    run_as "mkdir -p ~/WORK/CODE/REPO && git clone '$repo_url' ~/WORK/CODE/REPO/BentClaw"
fi

# ---- WSL: make the new user the default login ------------------------------
if grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease; then
    log 'WSL: setting default user'
    touch /etc/wsl.conf
    awk -v u="$openclaw_user" '
        /^\[/ { if (sec == "user" && !done) { print "default=" u; done = 1 } sec = tolower(substr($0, 2, index($0, "]") - 2)) }
        sec == "user" && /^[ \t]*default[ \t]*=/ { next }
        { print }
        END { if (sec == "user" && !done) print "default=" u; else if (!done) print "\n[user]\ndefault=" u }
    ' /etc/wsl.conf > /etc/wsl.conf.new && mv /etc/wsl.conf.new /etc/wsl.conf
    log 'Run "wsl.exe --terminate <distro>" from Windows to apply it.'
fi

log "Done. Log in as $openclaw_user and run: openclaw onboard --install-daemon"
