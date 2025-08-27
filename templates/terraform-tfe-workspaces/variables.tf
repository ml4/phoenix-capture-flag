variable "workspace_name" {
  type        = string
  description = "Workspace name"
}

variable "org" {
  type        = string
  description = "Workspace organization"
}

variable "auto_apply" {
  type        = bool
  description = "Set whether to auto or manual apply"
}

variable "tf_version" {
  type        = string
  description = "Set terraform core version to run in the workspace"
  default     = ">= 1.9.0"
}

variable "execution_mode" {
  type        = string
  description = "The type of execution (remote/local/agent) for this workspace"
  default     = "remote"
}

variable "agent_pool_id" {
  type        = string
  description = "The ID of an agent pool assigned to the workspace"
  default     = null
}

variable "project_id" {
  type        = string
  description = "The project in which to put the workspace"
}

# variable "workspace_tags" {
#   type        = list
#   description = "The tags of a workspace"
# }

variable "variable_sets" {
  type        = set(string)
  description = "A list of variable set to attach to the workspace"
  default     = null
}

# ## for hcpp checking run task
# #
# variable "task_id" {
#   type        = string
#   description = "Run task ID"
#   default     = null
# }

# variable "enforcement_level" {
#   type        = string
#   description = "Enforcement level of run task"
#   default     = "advisory"
# }

