# platform-team

This repository bootstraps a new **HCP Terraform** project and a standard set of **workspaces** for the Platform team within the HCP Terraform organization.
This illustrates the best practices of using only reusable child module calls from your workspace configurations to remove duplication of effort across your organization.
We recommend a dedicated project/workspace structure used to scale out the deployment of application teams' own projects and the workspaces therein. Here, we appropriate the top-level platform team workspace for an example app team project and workspaces for brevity.

> ⚠️ This configuration is designed to run inside [HCP Terraform](https://developer.hashicorp.com/terraform/cloud) and uses internal, versioned modules from the private registry.

---

## 📦 What it does

This Terraform workspace configuration (root module):

1. **Creates an HCP Terraform project**
2. **Creates example workspaces mapped to dev, test and prod operating environments**
   - Workspaces named `<team_name>-dev`, `<team_name>-test`, and `<team_name>-prod`
   - All attached to the created project
   - Configured with `auto_apply = true`

---

## 📁 Repo Structure

| File             | Purpose |
|------------------|---------|
| `main.tf`        | Calls the `project` and `workspace` modules |
| `variables.tf`   | Input variables for project name, workspace name, org, and token |
| `outputs.tf`     | Outputs the project ID for reference |
| `terraform.tf`   | Configures the TFC backend and `tfe` provider |

---

## 🔐 Prerequisites

This configuration expects:

- A long-lived **HCPT token** instantiated as an environment variable (used to authenticate the [TFE provider](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs))
- Execution to happen **within HCP Terraform**

---

## 🧱 Module References

This repo uses the following **child modules** hosted in the private registry:

- [`project`](https://app.terraform.io/app/Phoenix-AWS-Platform-Team/registry/modules/project/tfe)
- [`workspaces`](https://app.terraform.io/app/Phoenix-AWS-Platform-Team/registry/modules/workspaces/tfe)

Versions are pinned, per best practice, for stability.
