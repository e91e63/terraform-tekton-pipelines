module "main" {
  source = "../"

  trigger_template_conf = {
    name      = "javascript-test-build-deploy"
    namespace = trigger_template_conf.namespace
    params = [
      {
        description = "The SSH URL of the git repo with an npm package to build"
        name        = "git-repo-npm-url"
      },
    ]
    resource_templates = [
      {
        apiVersion = "tekton.dev/v1beta1"
        kind       = "PipelineRun"
        metadata = {
          generateName = "${kubernetes_manifest.pipeline_javascript_cicd.object.metadata.name}-run-$(uid)"
          namespace    = kubernetes_namespace.tekton_workers.metadata[0].name
        }
        spec = {
          pipelineRef = {
            name = kubernetes_manifest.pipeline_javascript_cicd.object.metadata.name
          }
          resources = [
            {
              name = "docker-image"
              resourceSpec = {
                params = [
                  {
                    name  = "url"
                    value = "registry.digitalocean.com/dmikalova/todo"
                  },
                ]
                type = "image"
              }
            },
            {
              name = "git-repo-infrastructure"
              resourceRef = {
                name = kubernetes_manifest.pipeline_resource_git_repo_dmikalova_infrastructure.object.metadata.name
              }
            },
            {
              name = "git-repo-npm"
              resourceSpec = {
                params = [
                  {
                    name  = "refspec"
                    value = "refs/heads/main:refs/heads/main"
                  },
                  {
                    name  = "revision"
                    value = "main"
                  },
                  {
                    name  = "url"
                    value = "$(tt.params.git-repo-npm-url)"
                  },
                ]
                type = "git"
              }
            },
          ]
          serviceAccountName = kubernetes_service_account.tekton_worker.metadata[0].name
        }
      },
    ]
  }
}
