# AGENTS.md — BentClaw

Governance contract for AI coding agents. 

# Project Description
Terraform lab deployment for OpenClaw on Azure VM - Foundry llm model capable. 

## Never do

- Never run `terraform apply` or `terraform destroy` without explicit user
  approval of a reviewed plan. `fmt`, `validate`, `tflint`, `plan` are always safe.
- Never read, print, edit, commit, or diff: `terraform.tfstate*`, `terraform.tfvars`,
  `backend.tf`, `.env`, `*.pem`, `.terraform/`, `.terraform.lock.hcl`. They are
  gitignored on purpose and hold real credentials/keys/state.
- Never echo secret values (`arm_client_secret`, `vm_localadmin_pswd`,
  `ssh_private_key` output) into logs, docs, or the README. New secret variables
  get `sensitive = true` and a placeholder in `terraform.tfvars.example` only.
- Never bump pinned provider versions (`~>` in `providers.tf`) or change
  `source_image_reference`, `os_disk`, VM `size`, NIC/IP config, or `user_data`
  (rendered `cloud-init.yaml`) without warning the user first — those **replace
  the VM**.

## Non-obvious gotchas

- No CI. `terraform fmt -recursive` + `validate` + `tflint` clean is the commit gate.
- `plan`/`apply` need ARM_* credentials and reachability of ipv4.icanhazip.com
  (the my-ip lookup feeds the NSG SSH rule). If auth fails, stop — don't edit
  files to work around it.
- `cloud-init` runs on first boot only; re-running OpenVPN bootstrap means
  deleting `azureclaw.ovpn.done` on the VM, not re-applying Terraform.
- NSG SSH is locked to the deployer's auto-detected public IP — keep it that way.
  `allow_gateway_public = false` is the intended default.
- The `vm_localadmin_pswd` default in `variables.tf` is a known lab placeholder —
  leave it unless asked.
- Windows dev box: generated key/profile files need restrictive ACLs
  (README "Connect") or OpenSSH refuses them.


