data "tfe_variable_set" "main" {
  for_each = toset(var.variable_sets)

  name         = each.key
  organization = var.org
}
