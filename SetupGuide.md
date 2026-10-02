# BentClaw Setup Guide

Post-deploy steps for the Azure VM. Replace `<placeholders>` with your values.
For the Docker variant see [docker/README.md](docker/README.md).

## 1. Rebuild the VM (optional)

```bash
terraform plan  -replace='azurerm_linux_virtual_machine.openclaw'
terraform apply -replace='azurerm_linux_virtual_machine.openclaw'
terraform output next_steps
```

## 2. Connect

```bash
ssh -i ~/.ssh/<key>.pem <user>@<vm_fqdn>
```

Tunnel the gateway (and optional extra ports) to your machine:

```bash
ssh -i ~/.ssh/<key>.pem \
  -L 18790:127.0.0.1:18789 \
  -L 9120:127.0.0.1:9119 \
  -L 8080:127.0.0.1:8080 \
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

## 6. Onboard OpenClaw

```bash
chmod 700 ~/.config
openclaw onboard --install-daemon
```

## 7. Allow the Control UI origins

The Control UI rejects origins it does not know. Allow the direct and tunneled addresses:

```bash
openclaw config set gateway.controlUi.allowedOrigins '["http://localhost:18789","http://127.0.0.1:18789","http://localhost:18790","http://127.0.0.1:18790"]' --strict-json
```

To also allow the VM's private IP (for example over OpenVPN), add `http://<vm_private_ip>:18789` and `:18790`.
To allow only the direct local addresses:

```bash
openclaw config set gateway.controlUi.allowedOrigins '["http://localhost:18789","http://127.0.0.1:18789"]' --strict-json
```

Confirm, then restart the gateway so the change applies:

```bash
openclaw config get gateway.controlUi.allowedOrigins --json
openclaw gateway restart
```

## 8. Verify and open the UI

```bash
openclaw gateway status --deep
openclaw gateway auth-token --show
```

With the tunnel from step 2 running, open <http://127.0.0.1:18790> and paste the token.

## 9. Personalize the agent (optional)

Send the agent a message like this once the UI is up:

*Wake up, my friend!*  
```text
I will call you `<name>`.  
Use `<emoji>` for emoji and `/home/<user>/<avatar>.png` for avatar.  
Vibe: `<one-line personality>`.
```

## Hermes (optional)

Uncomment the `# Hermes` line in `cloud-init.yaml` before deploying, or run it by hand:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive
```
