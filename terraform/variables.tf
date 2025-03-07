variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "japaneast"
}

variable "secret_key" {
  description = "Secret key for JWT token generation"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "development"
}
