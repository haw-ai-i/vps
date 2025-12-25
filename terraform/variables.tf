variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "bastion_ssh_user" {
  description = "Username for the bastion host"
  type        = string
  default     = "bastionuser"
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key for the initial admin"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
