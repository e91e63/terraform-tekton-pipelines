module "main" {
  source = "../"

  description = "Pipeline to test, build, and deploy JavaScript"
  name        = "javascript-test-build-deploy"
  namespace   = var.pipeline_conf.namespace
  params = [
    {
      default     = "$(resources.inputs.git-repo.path)"
      description = "Directory with package.json"
      name        = "context-path-npm"
      type        = "string"
    },
    {
      #   default     = "$(inputs.resources.git-repo.path)/digitalocean/cddc39/services/todo"
      description = "Directory with terragrunt.hcl"
      name        = "context-path-terragrunt"
      type        = "string"
    },
  ]
  resources = [
    {
      name = "docker-image"
      type = "image"
    },
    {
      name = "git-repo-javascript"
      type = "git"
    },
    {
      name = "git-repo-infrastructure"
      type = "git"
    },
  ]
  tasks = [
    {
      name = "test"
      params = [
        {
          name  = "context-path"
          value = "$(params.context-path-npm)"
        },
      ]
      resources = {
        inputs = [
          {
            name     = "git-repo"
            resource = "git-repo-javascript"
          },
        ]
      }
      taskRef = {
        kind = "Task"
        name = var.pipeline_conf.tasks.test
      }
    },
    {
      name = "build"
      params = [
        {
          name  = "version-tag"
          value = "$(tasks.version-tag.results.version-tag)"
        },
      ]
      resources = {
        inputs = [
          {
            name     = "git-repo"
            resource = "git-repo-javascript"
          },
        ]
        "outputs" = [
          {
            name     = "docker-image"
            resource = "docker-image"
          },
        ]
      }
      "runAfter" = [
        "tests",
      ]
      taskRef = {
        kind = "Task"
        name = var.pipeline_conf.tasks.build
      }
    },
    {
      name = "deploy"
      params = [
        {
          name  = "context-path"
          value = "$(params.context-path-terragrunt)"
        },
      ]
      resources = {
        inputs = [
          {
            name     = "git-repo"
            resource = "git-repo-infrastructure"
          },
        ]
      }
      "runAfter" = [
        "build",
      ]
      taskRef = {
        kind = "Task"
        name = var.pipeline_conf.tasks.deploy
      }
    },
  ]
}
