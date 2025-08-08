## AWS
#
variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "aws_default_region" {
  type = string
}

variable "ami" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "build_ssh_key" {
  type = string
}

## Azure
#
variable "azure_resource_group" {
  type = string
}

variable "azure_vnet" {
  type = string
}

variable "azure_subnet" {
  type = string
}

variable "arm_client_id" {
  type = string
}

variable "arm_client_secret" {
  type = string
}

variable "arm_subscription_id" {
  type = string
}

variable "arm_tenant_id" {
  type = string
}

# variable "managed_image_resource_group_name" {
#   type = string
# }

# variable "managed_image_name" {
#   type = string
# }