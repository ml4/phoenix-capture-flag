terraform {
  required_version = ">= 1.10.0"
  required_providers {
    tfe = {
      version = ">= 0.68.2"
      source  = "hashicorp/tfe"
    }
  }

  cloud {
    organization = "%%TEAM%%"
    workspaces {
      name = "platform-team"
    }
  }
}

provider "tfe" {
  token = var.hcpt_token
}
