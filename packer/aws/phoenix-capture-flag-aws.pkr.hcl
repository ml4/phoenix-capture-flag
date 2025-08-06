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
  ami_description           = "phoenix-capture-flag: minimal Ubuntu 24 image."
  ami_virtualization_type   = "hvm"
  # ami_regions               = var.regions
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
  source_ami                = var.ami #"ami-0ff2217d2295191c9" # see README
  skip_save_build_region    = false
  ssh_username              = "ubuntu"
  ssh_clear_authorized_keys = true
  ssh_keypair_name          = "id_rsa"
  ssh_private_key_file      = "/Users/ralph.richards/.ssh/id_rsa"
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

build {
  name        = "aws-build"
  description = "Phoenix AWS image for capture-the-flag Ubuntu 24"
  sources = [
    "source.amazon-ebs.phoenix-capture-flag-ubuntu-amd64"
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
    inline          = ["mv -f /tmp/id_rsa* /home/ubuntu/.ssh"]
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
