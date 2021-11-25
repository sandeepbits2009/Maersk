# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "terraformgroup" {
    name     = "ResourceGroupname"
    location = "eastus"
}

# Create virtual network
resource "azurerm_virtual_network" "terraformnetwork" {
    name                = "Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraformgroup.name

}

# Create subnet1
resource "azurerm_subnet" "terraformsubnet1" {
    name                 = "Subnet1"
    resource_group_name  = azurerm_resource_group.terraformgroup.name
    virtual_network_name = azurerm_virtual_network.terraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}
# Create subnet2
resource "azurerm_subnet" "terraformsubnet2" {
    name                 = "Subnet2"
    resource_group_name  = azurerm_resource_group.terraformgroup.name
    virtual_network_name = azurerm_virtual_network.terraformnetwork.name
    address_prefixes       = ["10.0.2.0/24"]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraformnsg" {
    name                = "NetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.terraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80,443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

}

# Create network interface1
resource "azurerm_network_interface" "terraformnic1" {
    name                      = "myNIC1"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.terraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.terraformsubnet1.id
        private_ip_address_allocation = "Dynamic"
    }
}

# Create network interface1
resource "azurerm_network_interface" "terraformnic2" {
    name                      = "myNIC2"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.terraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.terraformsubnet2.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_storage_account" "example1" {
  name                     = "storageaccountname"
  resource_group_name      = azurerm_resource_group.terraformgroup.name
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

data "azurerm_key_vault" "terrakv" {
  name                = "terrakv"
  resource_group_name = azurerm_resource_group.terraformgroup.name
}

data "azurerm_key_vault_secret" "kvsecret" {
name = "secret"
key_vault_id = data.azurerm_key_vault.terrakv.id
}

# Create virtual machine1
 resource   "azurerm_windows_virtual_machine"   "VM1"   { 
   name                    =   "myvm1"   
   location                =   "eastus" 
   resource_group_name     =   azurerm_resource_group.terraformgroup.name 
   network_interface_ids   =   [ azurerm_network_interface.terraformnic1.id ]
   size                    =   "Standard_B1s" 
   admin_username          =   "adminuser" 
   admin_password          =   data.azurerm_key_vault_secret.kvsecret.value 

   source_image_reference   { 
     publisher   =   "MicrosoftWindowsServer" 
     offer       =   "WindowsServer" 
     sku         =   "2019-Datacenter" 
     version     =   "latest" 
   } 

   os_disk   { 
     caching             =   "ReadWrite" 
     storage_account_type   =   "Standard_LRS" 
   } 
 } 
 
 # Create virtual machine2
 resource   "azurerm_windows_virtual_machine"   "VM2"   { 
   name                    =   "myvm2"   
   location                =   "eastus" 
   resource_group_name     =   azurerm_resource_group.terraformgroup.name 
   network_interface_ids   =   [ azurerm_network_interface.terraformnic2.id ]
   size                    =   "Standard_B1s" 
   admin_username          =   "adminuser" 
   admin_password          =   data.azurerm_key_vault_secret.kvsecret.value

   source_image_reference   { 
     publisher   =   "MicrosoftWindowsServer" 
     offer       =   "WindowsServer" 
     sku         =   "2019-Datacenter" 
     version     =   "latest" 
   } 

   os_disk   { 
     caching             =   "ReadWrite" 
     storage_account_type   =   "Standard_LRS" 
   } 
 }