## packer configuration for base image
#
packer {
  required_version          = ">= 1.11.2"
  required_plugins {
    amazon = {
      source                = "github.com/hashicorp/amazon"
      version               = "~> 1"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "amazon-ebs" "phoenix-capture-flag-ubuntu-amd64" {
  ami_name                  = "phoenix-capture-flag"
  ami_description           = "phoenix-capture-flag: minimal Ubuntu 22 image (because Azure has insufficient caught up)."
  ami_virtualization_type   = "hvm"
  access_key                = var.aws_access_key_id
  associate_public_ip_address = true
  aws_polling {
    delay_seconds           = 60
    max_attempts            = 200
  }
  enable_unlimited_credits  = true
  force_deregister          = true
  force_delete_snapshot     = true
  instance_type             = "t3.medium"
  region                    = var.aws_default_region         # ensure source_ami is correct for this region below
  run_tags = {
    OS_Version              = "Ubuntu"
    Release                 = "Latest"
    Base_AMI_ID             = "{{ .SourceAMI }}"
    Base_AMI_Name           = "{{ .SourceAMIName }}"
    Name                    = "phoenix-capture-flag"
  }
  run_volume_tags = {
    Status                  = "packer-delete-me"
  }
  secret_key                = var.aws_secret_access_key
  snapshot_tags             = {
    OS_Version              = "Ubuntu"
    Release                 = "Latest"
    Base_AMI_ID             = "{{ .SourceAMI }}"
    Base_AMI_Name           = "{{ .SourceAMIName }}"
  }
  source_ami                = var.ami # see README
  skip_save_build_region    = false
  ssh_username              = "ubuntu"
  ssh_clear_authorized_keys = false
  ssh_agent_auth            = false
  tags = {
    OS_Version              = "Ubuntu"
    Release                 = "Latest"
    Base_AMI_ID             = "{{ .SourceAMI }}"
    Base_AMI_Name           = "{{ .SourceAMIName }}"
  }
  subnet_id                 = var.subnet_id
  vpc_id                    = var.vpc_id
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
  os_type                           = "Linux"
  image_publisher                   = "Canonical"
  image_offer                       = "0001-com-ubuntu-server-jammy"
  image_sku                         = "22_04-lts"
}

build {
  name        = "multi-cloud-build"
  description = "Phoenix AWS image for capture-the-flag Ubuntu 24"
  sources = [
    "source.amazon-ebs.phoenix-capture-flag-ubuntu-amd64",
    "source.azure-arm.phoenix-capture-flag-ubuntu-amd64"
  ]

  provisioner "file" {
    source      = "/Users/ml4/.ssh/${var.build_ssh_key}"
    destination = "/tmp/id_rsa"
  }

  provisioner "file" {
    source      = "/Users/ml4/.ssh/${var.build_ssh_key}.pub"
    destination = "/tmp/id_rsa.pub"
  }

  ## add attendee ssh public keys to target ~/.ssh/authorized_keys file
  #
  provisioner "file" {
    source      = "../keys"
    destination = "/tmp/keys"
  }

  provisioner "file" {
    destination = "/tmp/multi-cloud-setup.sh"
    source      = "multi-cloud-setup.sh"
  }

  provisioner "file" {
    destination = "/tmp/flag"
    source      = "flag"
  }

  provisioner "shell" {
    execute_command  = "{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = ["mv -f /tmp/flag /etc"]
  }

  provisioner "shell" {
    execute_command  = "{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = ["/tmp/multi-cloud-setup.sh"]
  }
}
