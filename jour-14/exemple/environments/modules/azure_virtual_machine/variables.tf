# ==========================================
# VARIABLES OBLIGATOIRES
# ==========================================

variable "vm_name" {
  description = "Nom de la machine virtuelle"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.vm_name))
    error_message = "Le nom doit être en minuscules, chiffres, et tirets."
  }
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nom du groupe de ressources existant"
  type        = string
}

variable "subnet_id" {
  description = "ID du sous-réseau"
  type        = string
}

# ==========================================
# VARIABLES AVEC VALEURS PAR DÉFAUT
# ==========================================

variable "vm_size" {
  description = "Taille de la VM"
  type        = string
  default     = "Standard_B1s"
  
  validation {
    condition     = can(regex("^(Standard_|Basic_)", var.vm_size))
    error_message = "La taille doit commencer par Standard_ ou Basic_"
  }
}

variable "admin_username" {
  description = "Nom d'utilisateur admin"
  type        = string
  default     = "azureuser"
}

# ==========================================
# VARIABLES SENSIBLES
# ==========================================

variable "admin_password" {
  description = "Mot de passe admin"
  type        = string
  sensitive   = true
  # PAS DE DEFAULT - doit être fourni
}

variable "source_image" {
  description = "Image source pour la VM"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }
}

variable "tags" {
  description = "Tags à appliquer"
  type        = map(string)
  default     = {}
}