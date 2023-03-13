# Create the AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace
  resource_group_name = var.rg_name
  location            = var.resource_group_location
  friendly_name       = "${var.prefix} Workspace"
  description         = "${var.prefix} Workspace"
}

 # Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  resource_group_name      = var.rg_name
  location                 = var.resource_group_location
  name                     = var.hostpool
  friendly_name            = var.hostpool
  validate_environment     = false
  custom_rdp_properties    = "drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:0;redirectclipboard:i:0;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:0;use multimon:i:0;targetisaadjoined:i:1"
  description              = "${var.prefix} Terraform HostPool"
  type                     = "Personal"
  #type                     = "Pooled"
  start_vm_on_connect      = "true"
  #maximum_sessions_allowed = 16
  #load_balancer_type       = "DepthFirst" #[BreadthFirst DepthFirst]
  load_balancer_type          = "Persistent"
  personal_desktop_assignment_type = "Automatic"
}
 

#create registration info
resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "480h")
}

locals {
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
}


# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag" {
  resource_group_name = var.rg_name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  location            = var.resource_group_location
  type                = "Desktop"
  name                = "${var.prefix}-dag"
  friendly_name       = "Desktop AppGroup"
  description         = "AVD application group"
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool, azurerm_virtual_desktop_workspace.workspace]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}


#role Assignments

data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization User"
}

data "azurerm_role_definition" "VM_user_login" { # access an existing built-in role
  name = "Virtual Machine User Login"
}

data "azurerm_role_definition" "VM_Administrator_login" { # access an existing built-in role
  name = "Virtual Machine Administrator Login"
}



data "azuread_group" "avd_group" {
  display_name     = var.aad_group_name
}

resource "azurerm_role_assignment" "role" {
  scope              = azurerm_virtual_desktop_application_group.dag.id
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.avd_group.id
}

resource "azurerm_role_assignment" "VM_User_login_role" {
  scope              = var.rg_id
  role_definition_id = data.azurerm_role_definition.VM_user_login.id
  principal_id       = data.azuread_group.avd_group.id
}

resource "azurerm_role_assignment" "VM_Administrator_login_role" {
  scope              = var.rg_id
  role_definition_id = data.azurerm_role_definition.VM_Administrator_login.id
  principal_id       = data.azuread_group.avd_group.id
}

#Keyvault


data "azurerm_key_vault_secret" "userName" {
  name         = var.userNameSecret
  key_vault_id = var.kvId
}

data "azurerm_key_vault_secret" "password" {
  name         = var.passwordSecret
  key_vault_id = var.kvId
}


resource "random_string" "AVD_local_password" {
  count            = var.rdsh_count
  length           = 16
  special          = true
  min_special      = 2
 override_special = "*!@#?"
}


#Create VM's
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name = var.rg_name
  location            = var.resource_group_location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  
}

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = var.rdsh_count
  name                  = "${var.prefix}-${count.index + 1}"
  resource_group_name   = var.rg_name
  location              = var.resource_group_location
  size                  = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username      = data.azurerm_key_vault_secret.userName.value
  admin_password      = data.azurerm_key_vault_secret.password.value
  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  
    source_image_id = var.Image_ID

      identity {
    type = "SystemAssigned"
  }


  
}


resource "azurerm_virtual_machine_extension" "vmext_aadlogin" {
  count                      = var.rdsh_count
  auto_upgrade_minor_version = true
  name                       = "AADLoginForWindows"
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]

}



resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}${count.index + 1}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${var.hostpool}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS


}


