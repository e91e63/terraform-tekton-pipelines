module "main" {
  source = "../"

  conf = {
    name        = "javascript-test"
    namespace   = var.conf.namespace
    description = "Run JavaScript tests on repo"
    params = [
      {
        default     = "$(resources.inputs.git-repo.path)"
        description = "Repo directory with package.json"
        name        = "context-path"
        type        = "string"
      },
      # {
      #   default     = "cypress/base:16.5.0"
      #   description = "Cypress container image to run e2e tests"
      #   name        = "cypress-image"
      #   type        = "string"
      # },
      # {
      #   default     = "node:16-alpine"
      #   description = "Node container image to run tests"
      #   name        = "node-image"
      #   type        = "string"
      # },
    ]
    resources = {
      inputs = [
        {
          name = "git-repo"
          type = "git"
        },
      ]
    }
    results = [
      {
        name        = "version-tag"
        description = "The version tag for build artifacts"
      },
    ]
    steps = [
      {
        image      = var.conf.images.node
        name       = "npm-install"
        resources  = {}
        script     = file("./scripts/npm-install.sh")
        workingDir = "$(params.context-path)"
      },
      {
        image      = var.conf.images.node
        name       = "npm-fmt"
        resources  = {}
        script     = file("./scripts/npm-fmt.sh")
        workingDir = "$(params.context-path)"
      },
      {
        image      = var.conf.images.node
        name       = "npm-lint"
        resources  = {}
        script     = file("./scripts/npm-lint.sh")
        workingDir = "$(params.context-path)"
      },
      {
        image      = var.conf.images.node
        name       = "npm-tests-unit"
        resources  = {}
        script     = file("./scripts/npm-tests-unit.sh")
        workingDir = "$(params.context-path)"
      },
      {
        image      = var.conf.images.cypress
        name       = "npm-tests-e2e"
        resources  = {}
        script     = file("./scripts/npm-tests-e2e.sh")
        workingDir = "$(params.context-path)"
      },
      {
        env = [
          {
            name  = "RESULTS_PATH"
            value = "$(results.version-tag.path)"
          }
        ]
        image  = var.conf.images.alpine
        name   = "version-tag"
        script = file("./scripts/version-tag.sh")
        workingDir : "$(params.context-path)"
      },
    ]
  }
}
