# BentClaw tools image: the official OpenClaw image (Debian bookworm-slim, user
# `node`, openclaw already installed) plus the cloud-init.yaml toolset and sshd.
ARG OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
FROM ${OPENCLAW_IMAGE}

ARG REPO_URL=https://github.com/bentman/BentClaw.git

USER root
ENV DEBIAN_FRONTEND=noninteractive

# packages (cloud-init: packages); Node.js and openclaw come from the base image
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-transport-https ca-certificates curl gnupg lsb-release openssl \
      build-essential make cmake git g++ gh ffmpeg \
      python3 python3-openai python3-pip python3-venv \
      openssh-server \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /run/sshd

# Azure CLI (pip in a venv; the Microsoft apt repo lags new Debian releases)
RUN python3 -m venv /opt/azure-cli \
 && /opt/azure-cli/bin/pip install --no-cache-dir azure-cli \
 && ln -s /opt/azure-cli/bin/az /usr/local/bin/az

# sshd: key from a volume, only the node user, auth set by entrypoint.sh
RUN printf '%s\n' \
      'HostKey /etc/ssh/hostkeys/ssh_host_ed25519_key' \
      'PermitRootLogin no' \
      'AllowUsers node' \
      > /etc/ssh/sshd_config.d/bentclaw.conf

# CLIs (cloud-init: runcmd, same order), installed as the user
USER node
WORKDIR /home/node
RUN curl -fsSL https://claude.ai/install.sh | bash -s stable
RUN curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash
RUN curl -fsSL https://gh.io/copilot-install | bash

# user-local CLI path + repo clone (cloud-init: runcmd)
RUN echo 'export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc \
 && mkdir -p ~/WORK/CODE/REPO \
 && git clone "$REPO_URL" ~/WORK/CODE/REPO/BentClaw

USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh
EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
