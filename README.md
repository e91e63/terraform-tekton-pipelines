# Tekton Pipelines Modules

[![maintained by dmikalova.tech](https://img.shields.io/static/v1?&color=ccff90&label=maintained%20by&labelColor=424242&logo=&logoColor=fff&message=dmikalova.tech&&style=flat-square)](https://www.terraform.io/)
[![license](https://img.shields.io/static/v1?&color=e9e9e9&label=license&labelColor=424242&logo=&logoColor=fff&message=apache-2.0&&style=flat-square)](LICENSE)

[![terraform](https://img.shields.io/static/v1?&color=844fba&label=%20&labelColor=424242&logo=terraform&logoColor=fff&message=terraform&&style=flat-square)](https://www.terraform.io/)
[![tekton](https://img.shields.io/static/v1?&color=fd495c&label=%20&labelColor=424242&logo=tekton&logoColor=fff&message=tekton&&style=flat-square)](https://www.kubernetes.io/)
[![kubernetes](https://img.shields.io/static/v1?&color=326ce5&label=%20&labelColor=424242&logo=kubernetes&logoColor=fff&message=kubernetes&&style=flat-square)](https://www.kubernetes.io/)

This repo contains [Terraform modules](https://www.terraform.io/docs/language/modules/index.html) for managing [Tekton Pipelines](https://tekton.dev/) in [Kubernetes](https://kubernetes.io/).

See [dmikalova/infrastructure](https://gitlab.com/dmikalova/infrastructure/-/blob/main/digitalocean/e91e63/services/tekton/workflows/terragrunt.hcl) for a fully configured example.

## Features

- Create opinionated and reusable per language CI/CD pipelines.
- Current workflow is for JavaScript web apps. Workflows for Go, Terraform modules, and [git-xargs](https://github.com/gruntwork-io/git-xargs) are being planned.
- Includes reusable pipelines with tasks for testing, building, and deployment.
- Included tasks do the following:
  - Tests with unit test, end-to-end test, lint, format, and version tag generation steps.
  - Container builds with [Kaniko](https://github.com/GoogleContainerTools/kaniko).
  - GitOps deployments done by updating [an infrastructure repo](https://gitlab.com/dmikalova/infrastructure/-/commit/2b2eb3eb3f58fd475310f89efb59a067775ac5b4) with the version tag, committing and pushing the changes, and running [Terragrunt plan and apply](https://terragrunt.gruntwork.io/).
- Modules wrapping Tekton CRDs allow for complete customization. Wrappers are fully typed in Terraform with no YAML.
- Webhook endpoints are exposed through Traefik Ingress Routes. Webhooks URLs and tokens are output in Terraform Remote State. This can be consumed by [other Terraform modules](https://gitlab.com/e91e63/terraform-gitlab-projects/-/tree/main/modules/webhooks) that manage repo webhooks.
- Janitor cronjob automatically cleans up old and failed Tekton Runs, releasing Kubernetes Persistent Volume Claims.
