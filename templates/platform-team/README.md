# platform-team

This repository bootstraps a new **HCP Terraform** project and a standard set of **workspaces** for the Platform team within the HCP Terraform organization.
This illustrates the best practices of using only reusable child module calls from your workspace configurations to remove duplication of effort across your organization.
We recommend a dedicated project/workspace structure used to scale out the deployment of application teams' own projects and the workspaces therein. Here, we appropriate the top-level platform team workspace for an example app team project and workspaces for brevity.

> ⚠️ This configuration is designed to run inside [HCP Terraform](https://app.terraform.io/app/%%TEAM%%/workspaces) and uses internal, versioned modules from the private registry.

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
| `terraform.tf`   | Configures the HCP Terraform backend and `tfe` provider |
| `variables.tf`   | Input variables for project name, workspace name, org, and token |
| `main.tf`        | Calls the `project` and `workspace` modules into the graph calculation |

---

## 🔐 Prerequisites

This configuration expects:

- A long-lived **HCPT token** instantiated as an environment variable (used to authenticate the [HCP Terraform and Terraform Enterprise provider](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs))
- Execution to happen **within HCP Terraform**

---

## 🧱 Module References

This repository uses the following **child modules** hosted in the private registry:

- [`project`](https://app.terraform.io/app/%%TEAM%%/registry/modules/project/tfe)
- [`workspaces`](https://app.terraform.io/app/%%TEAM%%/registry/modules/workspaces/tfe)

Versions are pinned, per best practice, for stability.
