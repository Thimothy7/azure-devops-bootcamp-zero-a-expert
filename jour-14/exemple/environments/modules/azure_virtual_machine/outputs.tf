# ==========================================
# SORTIES DU MODULE
# ==========================================

output "vm_id" {
  description = "ID de la VM"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_private_ip" {
  description = "IP privée de la VM"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "vm_public_ip" {
  description = "IP publique (si créée)"
  value       = try(azurerm_public_ip.pip[0].ip_address, null)
}

output "vm_username" {
  description = "Nom d'utilisateur admin"
  value       = var.admin_username
  # Non-sensitive pour faciliter la connexion SSH
}

output "connection_info" {
  description = "Information de connexion SSH"
  value       = var.create_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.pip[0].ip_address}" : "No public IP: utilisez Azure Bastion"
}