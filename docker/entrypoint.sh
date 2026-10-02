#!/usr/bin/env bash
# Start sshd for the `node` user (the account the official image runs as).
set -euo pipefail

install -d -m 0755 /etc/ssh/hostkeys
[[ -f /etc/ssh/hostkeys/ssh_host_ed25519_key ]] \
    || ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/hostkeys/ssh_host_ed25519_key

install -d -m 0700 -o node -g node /home/node/.ssh
if [[ -n ${SSH_PUBLIC_KEY:-} ]]; then
    printf '%s\n' "$SSH_PUBLIC_KEY" > /home/node/.ssh/authorized_keys
    chown node:node /home/node/.ssh/authorized_keys
    chmod 0600 /home/node/.ssh/authorized_keys
fi

if [[ -n ${SSH_PASSWORD:-} ]]; then
    printf 'node:%s\n' "$SSH_PASSWORD" | chpasswd
    pw=yes
else
    usermod -p '*' node          # no password, but key login stays allowed
    pw=no
fi
printf 'PasswordAuthentication %s\n' "$pw" > /etc/ssh/sshd_config.d/bentclaw-auth.conf
[[ $pw == yes || -s /home/node/.ssh/authorized_keys ]] \
    || echo 'WARNING: set SSH_PUBLIC_KEY or SSH_PASSWORD; ssh login is impossible.' >&2

# ssh sessions don't inherit container env; let `openclaw` find the gateway token.
sed -i '/^OPENCLAW_GATEWAY_TOKEN=/d' /etc/environment
[[ -z ${OPENCLAW_GATEWAY_TOKEN:-} ]] || echo "OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN" >> /etc/environment

exec "$@"
