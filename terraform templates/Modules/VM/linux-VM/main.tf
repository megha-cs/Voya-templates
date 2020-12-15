data "azurerm_subnet" "example" {
  name                 = "Subnet1"
  virtual_network_name = "${var.virtual_network_name}"
  resource_group_name  = "${var.resource_group_name}"
}

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "linuxPublicIP"
    location                     = "${var.location}"
    resource_group_name          = "${var.resource_group_name}"
    allocation_method            = "Dynamic"

}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "linuxNetworkSecurityGroup"
    location            = "${var.location}"
    resource_group_name = "${var.resource_group_name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

}

resource "azurerm_network_interface" "myterraformnic" {
    name                        = "linuxNIC"
    location                    = "${var.location}"
    resource_group_name         = "${var.resource_group_name}"

    ip_configuration {
        name                          = "linuxNicConfiguration"
        subnet_id                     = "${data.azurerm_subnet.example.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }
}

resource "random_id" "randomId" {
   keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${var.resource_group_name}"
    }

    byte_length = 8
}
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${var.resource_group_name}"
    location                    = "${var.location}"
    account_replication_type    = "LRS"
    account_tier                = "Standard"

}

resource "azurerm_virtual_machine" "main" {
  name                  = "linuxVM"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
  vm_size               = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "linuxosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "linuxVM"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  #os_profile_linux_config {
   # disable_password_authentication = false
  #}
  tags = {
    environment = "staging"
  }
}
