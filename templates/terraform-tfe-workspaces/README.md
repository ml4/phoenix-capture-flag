# terraform-tfe-workspaces
HCPT/TFE workspace creation

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [tfe_workspace.main](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_pool_id"></a> [agent\_pool\_id](#input\_agent\_pool\_id) | The ID of an agent pool assigned to the workspace | `string` | `null` | no |
| <a name="input_auto_apply"></a> [auto\_apply](#input\_auto\_apply) | Set whether to auto or manual apply | `bool` | n/a | yes |
| <a name="input_execution_mode"></a> [execution\_mode](#input\_execution\_mode) | Which execution mode to use | `string` | `"remote"` | no |
| <a name="input_org"></a> [org](#input\_org) | Workspace organization | `string` | n/a | yes |
| <a name="input_terraform_version"></a> [terraform\_version](#input\_terraform\_version) | Set terraform core version to run in the workspace | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Workspace name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tw-tw-main-id"></a> [tw-tw-main-id](#output\_tw-tw-main-id) | TFE workspace main ID |
<!-- END_TF_DOCS -->
