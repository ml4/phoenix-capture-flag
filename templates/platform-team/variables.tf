variable "tfe_org" {
  description = "The name of the HCP Terraform organization"
  type        = string
}

variable "project_name" {
  description = "The name of the HCP Terraform project"
  type        = string
}

variable "workspace_name" {
  description = "The name of the HCP Terraform workspace"
  type        = string
}

variable "hcpt_token" {
  description = "Long lived HCPT Token"
  type        = string
  sensitive   = true
}