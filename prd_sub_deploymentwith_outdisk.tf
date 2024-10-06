#Ceylinco Life
#Author - Chamith Rasanka
#Date - 22-02-2024


provider   "azurerm"   { 
   version   =   ">= 2.0.0"
   skip_provider_registration = "true" 
   features   {} 
 } 
 {}
 
terraform {
  backend "azurerm" {}
}

# refer to a resource group CEY-RG-Prod
data "azurerm_resource_group" "prd-rg" {
  name = "CEY-RG-Prod"
}

#Virtual network CEY-PRD-SAP-VNET
data "azurerm_virtual_network" "prd-sap-vnet" {
  name                 = "CEY-PRD-SAP-VNET"
  resource_group_name  = "CEY-RG-Prod"
}

#Subnet CEY-PRD-APP-SUBNET
data "azurerm_subnet" "prd-app-snet" {
  name                 = "CEY-PRD-APP-SUBNET"
  virtual_network_name = "CEY-PRD-SAP-VNET"
  resource_group_name  = "CEY-RG-Prod"
}

#Subnet CEY-PRD-DB-SUBNET
data "azurerm_subnet" "prd-db-snet" {
  name                 = "CEY-PRD-DB-SUBNET"
  virtual_network_name = "CEY-PRD-SAP-VNET"
  resource_group_name  = "CEY-RG-Prod"
}

# refer to a resource group CEY-RG-DMZ
data "azurerm_resource_group" "dmz-rg" {
  name = "CEY-RG-DMZ"
}

#Virtual network CEY-DMZ-VNET
data "azurerm_virtual_network" "dmz-vnet" {
  name                 = "CEY-DMZ-VNET"
  resource_group_name  = "CEY-RG-DMZ"
}

#Subnet CEY-DMZ-SUBNET
data "azurerm_subnet" "dmz-snet" {
  name                 = "CEY-DMZ-SUBNET"
  virtual_network_name = "CEY-DMZ-VNET"
  resource_group_name  = "CEY-RG-DMZ"
}

#Subnet CEY-MGT-SUBNET
data "azurerm_subnet" "mgmt-snet" {
  name                 = "CEY-MGT-SUBNET"
  virtual_network_name = "CEY-DMZ-VNET"
  resource_group_name  = "CEY-RG-DMZ"
}

#################Jump Server Deployment#########

# resource group CEY-RG-SHARED
resource "azurerm_resource_group" "shared-rg" {
  name     = "CEY-RG-SHARED"
  location = var.location
}

resource "azurerm_network_interface" "jump-nic" {
  name                = "jump-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.dmz-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.dmz-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "jump-vm" {
  name                = "CEY-PRD-JUMP01"
  resource_group_name = azurerm_resource_group.shared-rg.name
  location            = var.location
  size                = "Standard_D4as_v4"
  admin_username      = "ceyjumpadmin"
  admin_password      = "_BzuqpCFw3ndrfXs"
  network_interface_ids = [
	azurerm_network_interface.jump-nic.id,
	]
  zone				  = "1"


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  
  tags = {
    environment = "ENV-JUMP"
  }
}

######Proximity Placement Groups###############

resource "azurerm_proximity_placement_group" "prdgroup" {
  name                = "prd"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.prd-rg.name

  tags = {
    environment = "ENV-PROD"
  }
}

##########CEY-PRD-ERPAPP01#################

resource "azurerm_network_interface" "prdapp-nic" {
  name                = "prdapp-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.prd-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.prd-app-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "appvm01" {
  name                = "CEY-PRD-ERPAPP01"
  resource_group_name = data.azurerm_resource_group.prd-rg.name
  location            = var.location
  size                = "Standard_E8as_v4"
  admin_username      = "ceysapadmin"
  admin_password      = "ol!kVXibwm-HyK]{"
  disable_password_authentication = false
  computer_name	      = "prdapp"
  network_interface_ids = [
	azurerm_network_interface.prdapp-nic.id,
	]
  proximity_placement_group_id = azurerm_proximity_placement_group.prdgroup.id
  zone				  = "3" 
 
 os_disk {
    name		         = "prdapp01_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-sap-15-sp4"
    sku       = "gen2"
    version   = "latest"
  }

 tags = {
    environment = "ENV-PROD"
  }
}


##########CEY-PRD-ERPDB01#################

resource "azurerm_network_interface" "prddb-nic" {
  name                = "prddb-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.prd-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.prd-db-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "dbvm01" {
  name                = "CEY-PRD-ERPDB01"
  resource_group_name = data.azurerm_resource_group.prd-rg.name
  location            = var.location
  size                = "Standard_M32ls"
  admin_username      = "ceysapadmin"
  admin_password      = "#i-NDcHL+oawc?Yl"
  disable_password_authentication = false
  computer_name	      = "prddbapp"
  network_interface_ids = [
	azurerm_network_interface.prddb-nic.id,
	]
  proximity_placement_group_id = azurerm_proximity_placement_group.prdgroup.id
	
  zone				  = "3" 
 
 os_disk {
    name		         = "prddb01_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-sap-15-sp4"
    sku       = "gen2"
    version   = "latest"
  }

 tags = {
    environment = "ENV-PROD"
  }
}

##########CEY-PRD-GATEWAY01#################

resource "azurerm_network_interface" "prdgtw-nic" {
  name                = "prdgtw-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.prd-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.prd-app-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "gtwvm01" {
  name                = "CEY-PRD-GATEWAY01"
  resource_group_name = data.azurerm_resource_group.prd-rg.name
  location            = var.location
  size                = "Standard_E8as_v4"
  admin_username      = "ceysapadmin"
  admin_password      = "ol!kVXibwm-HyK]{"
  disable_password_authentication = false
  computer_name	      = "gtwapp"
  network_interface_ids = [
	azurerm_network_interface.prdgtw-nic.id,
	]
  proximity_placement_group_id = azurerm_proximity_placement_group.prdgroup.id
  zone				  = "3" 
 
 os_disk {
    name		         = "prdgtw_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-sap-15-sp4"
    sku       = "gen2"
    version   = "latest"
  }

 tags = {
    environment = "ENV-PROD"
  }
}


##########CEY-PRD-PIPO01#################

resource "azurerm_network_interface" "prdpi-nic" {
  name                = "prdpi-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.prd-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.prd-app-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "pivm01" {
  name                = "CEY-PRD-GATEWAY01"
  resource_group_name = data.azurerm_resource_group.prd-rg.name
  location            = var.location
  size                = "Standard_E8as_v4"
  admin_username      = "ceysapadmin"
  admin_password      = "ol!kVXibwm-HyK]{"
  disable_password_authentication = false
  computer_name	      = "piapp"
  network_interface_ids = [
	azurerm_network_interface.prdpi-nic.id,
	]
  proximity_placement_group_id = azurerm_proximity_placement_group.prdgroup.id
  zone				  = "3" 
 
 os_disk {
    name		         = "prdpi_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
	
    
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-sap-15-sp4"
    sku       = "gen2"
    version   = "latest"
  }

 tags = {
    environment = "ENV-PROD"
  }
}

##########CEY-PRD-BIBO01#################

resource "azurerm_network_interface" "prdbi-nic" {
  name                = "prdbi-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.prd-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.prd-app-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "bivm01" {
  name                = "CEY-PRD-BIBO01"
  resource_group_name = data.azurerm_resource_group.prd-rg.name
  location            = var.location
  size                = "Standard_E2as_v4"
  admin_username      = "ceysapadmin"
  admin_password      = "ol!kVXibwm-HyK]{"
  network_interface_ids = [
	azurerm_network_interface.prdbi-nic.id,
	]
  zone				  = "3"


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  
  tags = {
    environment = "ENV-PROD"
  }
}


######CEY-PRD-SAPROUTER01#################

resource "azurerm_network_interface" "sprouter-nic" {
  name                = "sprouter-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.dmz-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.dmz-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "sproutervm01" {
  name                = "CEY-PRD-SAPROUTER01"
  resource_group_name = data.azurerm_resource_group.dmz-rg.name
  location            = var.location
  size                = "Standard_D2as_v4"
  admin_username      = "ceysapadmin"
  admin_password      = "ol!kVXibwm-HyK]{"
  disable_password_authentication = false
  computer_name	      = "sprouter"
  network_interface_ids = [
	azurerm_network_interface.sprouter-nic.id,
	]
  zone				  = "3" 
 
 os_disk {
    name		         = "sprouter_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-sap-15-sp4"
    sku       = "gen2"
    version   = "latest"
  }

 tags = {
    environment = "ENV-PROD"
  }
}


######CEY-PRD-WD01#################

resource "azurerm_network_interface" "wd-nic" {
  name                = "wd-nic-01"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.dmz-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.dmz-snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "wdvm01" {
  name                = "CEY-PRD-WD01"
  resource_group_name = data.azurerm_resource_group.dmz-rg.name
  location            = var.location
  size                = "Standard_E2as_v4"
  admin_username      = "ceysapadmin"
  admin_password      = "ol!kVXibwm-HyK]{"
  disable_password_authentication = false
  computer_name	      = "wd"
  network_interface_ids = [
	azurerm_network_interface.wd-nic.id,
	]
  zone				  = "3" 
 
 os_disk {
    name		         = "wd_osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-sap-15-sp4"
    sku       = "gen2"
    version   = "latest"
  }

 tags = {
    environment = "ENV-PROD"
  }
}

