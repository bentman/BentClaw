# 🏛️ BentHermes — AI Agent Dev-Lab on Azure (Terraform)

Deploys [Hermes Agent](https://hermes-agent.nousresearch.com/) on a single Azure Linux VM: public IP, SSH locked to your IP, OpenVPN for everything else. No Bastion, no Key Vault.

## Why Hermes?

This lab began life as BentClaw, built around OpenClaw. OpenClaw proved an enthusiastic colleague: config schemas that shifted between updates, gateway auth nobody could explain, and a gift for taking itself apart overnight. After one recursive lint-fix loop produced a $100 token bill, we parted ways amicably.

[Hermes Agent](https://hermes-agent.nousresearch.com/) (Nous Research) replaced it. It keeps persistent memory, loads reusable skills on demand, and writes new ones itself. Set a budget alarm anyway.

The OpenClaw material is kept, unmaintained, in [`OpenClaw/`](OpenClaw/) (guide, Linux script, Docker).

## What you get

- Resource group, VNet and a static-IP Ubuntu VM (`Standard_B2s`, 2 vCPU / 4 GB) with a generated SSH key
- NSG: SSH only from your auto-detected public IP; OpenVPN (UDP 1194) open
- OpenVPN server on the VM (profile `azureclaw.ovpn`)
- Hermes Agent, azure-cli, ffmpeg, git, Terraform and TFLint installed by cloud-init on first boot
- A private Blob container for off-VM Hermes backups (`storage.tf`)

Cost: about $35/month. `terraform destroy` or deallocating the VM stops compute billing.

## 1. Prerequisites

- Terraform >= 1.6.0
- Azure CLI logged in (`az login`)
- Providers registered once:
  ```
  az provider register --namespace Microsoft.Compute
  az provider register --namespace Microsoft.Network
  ```

## 2. Configure

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in the arm_* values
cp backend.tf.example backend.tf               # only if using a remote state backend
```

Both files are gitignored. Keep it that way.

## 3. Check, plan, deploy

```bash
terraform fmt -recursive
terraform init
terraform validate && tflint
terraform plan
terraform apply          # only after reading the plan
```

Changes to cloud-init (`user_data`), image, disk, size or NIC settings replace the VM. Read the plan.

## 4. Connect

```bash
terraform output -raw ssh_private_key > ~/.ssh/azureclaw_key.pem
chmod 600 ~/.ssh/azureclaw_key.pem
ssh -i ~/.ssh/azureclaw_key.pem <vm_localadmin_user>@$(terraform output -raw vm_public_name)
```

On Windows, restrict the key's ACL or OpenSSH refuses it:
`icacls <file> /inheritance:r /grant:r "<DOMAIN>\<user>:R"`

## 5. Finish Hermes setup

Cloud-init takes about 10 minutes. Then, on the VM:

```bash
tail /var/log/cloud-init-output.log
hermes doctor
hermes setup
hermes gateway install && hermes gateway start
```

Full walkthrough (dashboard, API server, auth): [Guide_Hermes.md](Guide_Hermes.md).

## 6. Reach the gateway and WebUI

Tunnel over SSH (no VPN needed):

```bash
ssh -i ~/.ssh/azureclaw_key.pem -L 8643:127.0.0.1:8642 -L 9120:127.0.0.1:9119 <user>@<vm_fqdn>
```

Or fetch the OpenVPN profile (`terraform output -raw openvpn_config_file` prints the scp command), import it, and browse to the VM's private IP (ports are in `terraform output`).

Opening the ports directly (`allow_hermes_gateway_public`, `allow_hermes_webui_public`) is off by default. Leave it that way.

## 7. Backup storage

`storage.tf` creates a private Blob container (`hermes-backups`) reachable only from the VM subnet, and grants the VM identity write access. It is infrastructure only; no upload job is installed. Names and URL are in the Terraform outputs.

## Outputs

`terraform output` lists the resource group, VM public IP / FQDN / private IP, service ports, the OpenVPN profile command, and the sensitive `ssh_private_key`.

## Sizing

`Standard_B2s` (~$30/mo) suits one user and bursty work. For heavier use, try `Standard_D2s_v5` (8 GB, ~$65/mo).

## Cleanup

```bash
terraform destroy
```
