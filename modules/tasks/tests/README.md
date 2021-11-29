# Test Task

This folder contains a [Terraform module](https://terraform.io/docs/language/modules/index.html) for creating a standardized Tekton task for running tests. A calling module for a language passes in the container images and test scripts that are run. The test steps include formatting, linting, unit tests, end to end tests, and deriving a version tag.
