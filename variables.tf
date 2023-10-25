variable "rg_name" {
  type        = string
  default     = "RG-TFAVD"
  description = "Name of the Resource group in which to deploy service objects"
}


variable "rg_id" {
  type        = string
  default     = "/subscriptions/123456789-2c34-4af1-5678-ddbcc9f05dc4/resourceGroups/RG-TFAVD"
  description = "Location of the Resource group in which to deploy service objects"
}

variable "vnet_name" {
  type        = string
  default     = "Vnet-TFAVD"
  description = "Name of the VNET in which to deploy service objects"
}
  
variable "subnet_id" {
  type        = string
  default     = "/subscriptions/123456789-2c34-4af1-5678-ddbcc9f05dc4/resourceGroups/RG-TFAVD/providers/Microsoft.Network/virtualNetworks/Vnet-TFAVD/subnets/AVD"
  description = "ID of the subnet in which to deploy service objects"
}

variable "resource_group_location" {
  default     = "northeurope"
  description = "Location of the resource group."
}


variable "prefix" {
  type        = string
  default     = "VM-AVD-V1"
  description = "Prefix of the name of the AVD machine(s)"
}

variable "workspace" {
  type        = string
  description = "Name of the Azure Virtual Desktop workspace"
  default     = "AVD TF WS V1"
}

variable "hostpool" {
  type        = string
  description = "Name of the Azure Virtual Desktop host pool"
  default     = "AVD-TF-HP-V1"
}


variable "aad_group_name" {
  type        = string
  default     = "AVDAllow"
  description = "Azure Active Directory Group for  AVD users"
}


###  session host ###

variable "Image_ID" {
  type        = string
  default     = "/subscriptions/123456789-2c34-4af1-5678-ddbcc9f05dc4/resourceGroups/AVD-RG/providers/Microsoft.Compute/images/Elbit-GoldenImage-image-test-2603"
  description = "Resource ID of the VM image version from the gallery"
}

variable "rdsh_count" {
  description = "Number of AVD machines to deploy"
  default     = 2
}



variable "vm_size" {
  description = "Size of the machine to deploy"
  default     = "Standard_DS2_v2"
}

variable "kvId" {
  type = string
  description = "Key Voult"
  default = "/subscriptions/123456789-2c34-4af1-5678-ddbcc9f05dc4/resourceGroups/KeyVaultRG/providers/Microsoft.KeyVault/vaults/Idit-Keyvault"
}

variable "userNameSecret" {
  type = string
  default = "DefaultAdminUser"
}

variable "passwordSecret" {
  type = string
  default = "DefaultAdminPassword"
}



