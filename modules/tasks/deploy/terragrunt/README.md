# Terragrunt Deploy Task

This folder contains a [Terraform module](https://terraform.io/docs/language/modules/index.html) for creating a Tekton task that run a Terragrunt deploy. The version tag passed in is updated in a given `terragrunt.hcl` and `git commit`ed. Then `terragrunt plan` and `terragrunt apply` deploys any changes.
