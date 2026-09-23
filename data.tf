#################### DATA ####################

# What's my IP? (from where you are running terraform)
# Used to lock NSG rules down to the deployer's public IP
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  # Trim whitespace/newline from the IP lookup response
  my_ip = chomp(data.http.myip.response_body)

  # shared naming / addressing (single source of truth for all files)
  rg_name        = "rg-${var.project_name}-${var.location}"
  vm_private_ip  = cidrhost(var.subnet_prefix, 8) // "10.0.2.8" by default
  vm_common_name = "vm-${var.project_name}"
}

