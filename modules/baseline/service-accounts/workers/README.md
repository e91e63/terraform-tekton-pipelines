# Workers Service Account

This folder contains a [Terraform module](https://terraform.io/docs/language/modules/index.html) for creating a [Kubernetes service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) for use in [Tekton tasks](../../../tekton/task). The service account has Docker and Git SSH secrets, which Tekton will automatically mount into a Tekton tasks's containers.
