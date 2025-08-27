resource "tfe_project" "main" {
  organization = var.org
  name         = var.project
}
