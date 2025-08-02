packer {
  required_version = ">= 1.11.2"
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "azure-arm" "phoenix-capture-flag-ubuntu-amd64" {
  subscription_id                   = var.arm_subscription_id
  client_id                         = var.arm_client_id
  client_secret                     = var.arm_client_secret
  tenant_id                         = var.arm_tenant_id

  managed_image_name                = "phoenix-capture-flag"
  managed_image_resource_group_name = var.azure_resource_group
  location                          = "UK South"
  vm_size                           = "Standard_DS1_v2"

  # resource_group_name               = var.azure_resource_group
  # virtual_network_name              = var.azure_vnet
  # virtual_network_subnet_name       = var.azure_subnet

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts"
}

build {
  name        = "azure-build"
  description = "Phoenix Azure image for capture-the-flag Ubuntu 24"
  sources = [
    "source.azure-arm.phoenix-capture-flag-ubuntu-amd64"
  ]

  provisioner "file" {
    source      = "/Users/ralph.richards/.ssh/id_rsa"
    destination = "/tmp/id_rsa"
  }

  provisioner "file" {
    source      = "/Users/ralph.richards/.ssh/id_rsa.pub"
    destination = "/tmp/id_rsa.pub"
  }

  provisioner "shell" {
    execute_command  = "{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline = [
      "mkdir -p /home/ubuntu/.ssh",
      "mv -f /tmp/id_rsa* /home/ubuntu/.ssh",
      "chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa*",
      "chmod 600 /home/ubuntu/.ssh/id_rsa"
    ]
  }

  provisioner "file" {
    destination = "/tmp/flag"
    source      = "flag"
  }

  provisioner "shell" {
    execute_command  = "{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = ["mv -f /tmp/flag /etc"]
  }
}