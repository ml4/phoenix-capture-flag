# terraform-tfe-project
Terraform child module to manage an HCP Terraform project.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [tfe_project.main](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/project) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_org"></a> [org](#input\_org) | Organisation to put the project in | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project to create | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tp-tp-main-id"></a> [tp-tp-main-id](#output\_tp-tp-main-id) | TFE Project main ID |
<!-- END_TF_DOCS -->


