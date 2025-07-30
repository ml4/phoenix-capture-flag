## packer configuration for base image
#
packer {
  required_version          = ">= 1.11.2"
  required_plugins {
    amazon = {
      source                = "github.com/hashicorp/amazon"
      version               = "~> 1"
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
  ssh_keypair_name          = "ml4"
  ssh_private_key_file      = "~/.ssh/ml4"
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
  description = "Phoenix image for capture-the-flag packer ubuntu24 stock marketplace image"
  sources = [
    "source.amazon-ebs.phoenix-capture-flag-ubuntu-amd64"
  ]

  ## move ubuntu ssh access into place
  #
  provisioner "file" {
    source      = "/Users/ml4/.ssh/ml4"
    destination = "/tmp/ml4"
  }

  provisioner "file" {
    source      = "/Users/ml4/.ssh/ml4.pub"
    destination = "/tmp/ml4.pub"
  }

  provisioner "shell" {
    execute_command  = "{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = ["mv -f /tmp/ml4* /home/ubuntu/.ssh"]
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
