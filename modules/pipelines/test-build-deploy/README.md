# Test, Build, and Deploy Pipeline

This folder contains a [Terraform module](https://terraform.io/docs/language/modules/index.html) for creating standardized Tekton pipelines. This can be used to create similar pipelines for different languages. A calling module for a language passes in the Tekton tasks that are run. This module will then create a Tekton trigger, event listener, and open up an ingress route for webhooks.
