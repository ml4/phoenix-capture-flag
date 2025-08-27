
module "project" {
  source  = "app.terraform.io/%%TEAM%%/project/tfe"
  version = "1.0.0"
  org     = var.tfe_org
  project = var.project_name
}

module "workspace_dev" {
  source  = "app.terraform.io/%%TEAM%%/workspaces/tfe"
  version = "1.0.0"
  workspace_name = "${var.workspace_name}-dev"
  org            = var.tfe_org
  project_id     = module.project.tp-tp-main-id
  auto_apply     = true
  variable_sets  = []
}

module "workspace_test" {
  source  = "app.terraform.io/%%TEAM%%/workspaces/tfe"
  version = "1.0.0"
  workspace_name = "${var.workspace_name}-test"
  org            = var.tfe_org
  project_id     = module.project.tp-tp-main-id
  auto_apply     = true
  variable_sets  = []
}

module "workspace_prod" {
  source  = "app.terraform.io/%%TEAM%%/workspaces/tfe"
  version = "1.0.0"
  workspace_name = "${var.workspace_name}-prod"
  org            = var.tfe_org
  project_id     = module.project.tp-tp-main-id
  auto_apply     = true
  variable_sets  = []
}
