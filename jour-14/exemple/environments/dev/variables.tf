variable "environment" {
  type        = string
  description = "Environnement"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment invalide"
  }
}

variable "project_name" {
  type        = string
  description = "Nom du projet"
  default     = "enterprise-app"
}

variable "location" {
  type        = string
  description = "Région"
  default     = "canadacentral"
}

variable "deployed_by" {
  type        = string
  description = "Nom de l'utilisateur qui déploie"
  default     = "donaldprogrammeur"
}
