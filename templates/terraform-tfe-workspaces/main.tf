resource "tfe_workspace" "main" {
  name              = var.workspace_name
  organization      = var.org
  auto_apply        = var.auto_apply
  terraform_version = var.tf_version # always get the latest version when the workspace drops
  project_id        = var.project_id
  # workspace_tags      = var.workspace_tags
}

resource "tfe_workspace_settings" "main" {
  agent_pool_id       = var.agent_pool_id
  workspace_id        = tfe_workspace.main.id
  execution_mode      = var.execution_mode
  global_remote_state = true
}

resource "tfe_workspace_variable_set" "main" {
  for_each = var.variable_sets

  variable_set_id = data.tfe_variable_set.main[each.value].id
  workspace_id    = tfe_workspace.main.id
}

# resource "tfe_workspace_run_task" "main" {
#   count             = var.task_id == null ? 0 : 1
#   task_id           = var.task_id
#   workspace_id      = tfe_workspace.main.id
#   enforcement_level = var.enforcement_level
# }
