# ==========================================
# RESSOURCES ALÉATOIRES POUR UNICITÉ
# ==========================================

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# ==========================================
# IP PUBLIQUE (OPTIONNELLE)
# ==========================================

resource "azurerm_public_ip" "pip" {
  # count = 0 ou 1 selon var.create_public_ip
  count = var.create_public_ip ? 1 : 0
  
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.tags
}

# ==========================================
# INTERFACE RÉSEAU
# ==========================================

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = try(azurerm_public_ip.pip[0].id, null)
    # try(..., null) = si la ressource existe, prend son ID, sinon null
  }
}

# ==========================================
# MACHINE VIRTUELLE LINUX
# ==========================================

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.vm_size
  
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false
  
  # DISQUE OS
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  
  # IMAGE SOURCE
  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }
  
  tags = merge(var.tags, {
    "OS" = var.source_image.offer
  })
  
  # DONNÉES DE BOOT (script d'initialisation)
  custom_data = base64encode(templatefile("${path.module}/cloud_init.tftpl", {
    hostname = var.vm_name
  }))
}

# ==========================================
# BLOCKER POUR DISQUE MANAGÉ (optionnel)
# ==========================================

resource "azurerm_managed_disk" "data_disk" {
  count = var.data_disk_size_gb != null ? 1 : 0
  
  name                 = "${var.vm_name}-datadisk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  
  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach" {
  count = var.data_disk_size_gb != null ? 1 : 0
  
  managed_disk_id    = azurerm_managed_disk.data_disk[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = 0
  caching            = "ReadWrite"
}