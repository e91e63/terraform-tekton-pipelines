# Janitor

This folder contains [Terraform modules](https://terraform.io/docs/language/modules/index.html) for creating janitor [Kubernetes cron jobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/). These jobs regularly clean up resources that Tekton may leave behind. Clean up tasks include:

- Tekton pipeline runs that can have leftover [Kubernetes persistent volumes](https://kubernetes.io/docs/concepts/storage/volumes/) which cost money.
