#################### OUTPUTS ####################

##### main.tf outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.openclaw.name
}

output "vm_public_ip" {
  description = "Public IP address of the OpenClaw VM"
  value       = azurerm_public_ip.vm_pip.ip_address
}

output "vm_public_name" {
  description = "Public DNS Name of the OpenClaw VM"
  value       = azurerm_public_ip.vm_pip.fqdn
}

output "ssh_private_key" {
  description = "SSH private key for the VM (save to ~/.ssh/openclaw_key.pem)"
  value       = tls_private_key.openclaw_ssh.private_key_pem
  sensitive   = true
}

output "ssh_command" {
  description = "Ready-to-use SSH command (extract the private key first)"
  value       = "ssh -i ~/.ssh/openclaw_key.pem ${var.vm_localadmin_user}@${azurerm_public_ip.vm_pip.fqdn}"
  sensitive   = true
}

output "vm_private_ip" {
  description = "Private IP of the VM (gateway target over VPN)"
  value       = local.vm_private_ip
}

output "openvpn_port" {
  description = "OpenVPN server port (UDP)"
  value       = var.openvpn_port
}

output "gateway_port" {
  description = "OpenClaw gateway (WebSocket/dashboard) port"
  value       = var.gateway_port
}

output "openvpn_config_file" {
  description = "azureclaw.ovpn - generated on the VM at first boot; retrieve it with this command"
  value       = "scp -i ~/.ssh/openclaw_key.pem ${var.vm_localadmin_user}@${azurerm_public_ip.vm_pip.fqdn}:~/azureclaw.ovpn ."
  sensitive   = true
}

##### install / verify next steps
output "next_steps" {
  description = "Post-deploy steps"
  sensitive   = true
  value       = <<-EOT
    1. terraform output -raw ssh_private_key > ~/.ssh/openclaw_key.pem
    2. ssh -i ~/.ssh/openclaw_key.pem ${var.vm_localadmin_user}@${azurerm_public_ip.vm_pip.fqdn}
    3. Wait ~10 min for cloud-init (apt upgrade + openclaw install), then: tail /var/log/cloud-init-output.log
    4. Verify: openclaw --version && openclaw doctor
    5. When ready, run onboarding + install the gateway service: openclaw onboard --install-daemon
    6. terraform output -raw openvpn_config_file   # scp azureclaw.ovpn from the VM
    7. Import azureclaw.ovpn into your OpenVPN client; gateway at http://${local.vm_private_ip}:${var.gateway_port}
  EOT
}
