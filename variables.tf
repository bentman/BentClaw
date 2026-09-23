#################### VARIABLES ####################
########## SECRETS VARIABLES 
#####  Declare confidential variables here
#####  Store secret values in *.tfvars file
#####  Check .gitignore in repo for details
########## SECRETS VARIABLES 

variable "arm_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "arm_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "arm_client_id" {
  description = "Azure Client ID (Service Principal ID)"
  type        = string
  sensitive   = true
}

variable "arm_client_secret" {
  description = "Azure Client Secret (Service Principal Secret)"
  type        = string
  sensitive   = true
}

variable "vm_localadmin_user" {
  description = "VM local admin username"
  type        = string
  default     = "localadmin"
  sensitive   = true
}

variable "vm_localadmin_pswd" {
  description = "VM local admin password"
  type        = string
  default     = "P@ssw0rd!234"
  sensitive   = true
}

#################### VARIABLES ####################

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "azureclaw"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "vm_size" {
  description = "The size of the Virtual Machine. Standard_B2s = 2 vCPU / 4 GB (~$30/mo), sweet spot for light OpenClaw usage"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 128
}

########## network VARIABLES
variable "vnet_prefix" {
  description = "Address space of the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "Address prefix of the VM subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "gateway_port" {
  description = "OpenClaw gateway (WebSocket/dashboard) port"
  type        = number
  default     = 18789
}

variable "openvpn_port" {
  description = "OpenVPN server port (UDP), open to any public IP"
  type        = number
  default     = 1194
}

# caution: exposing the gateway to the internet bypasses SSH-tunnel access
variable "allow_gateway_public" {
  description = "Open the gateway port to the deployer's IP (instead of tunneling over SSH)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    "source"      = "terraform"
    "project"     = "azureclaw"
    "environment" = "lab"
  }
}
