module "main" {
  source = "../"

  trigger_binding_conf = {
    name      = "javascript-build-test-deploy"
    namespace = var.trigger_binding_conf.namespace
    params = [
      {
        name  = "git-repo-npm-url"
        value = "$(body.repository.git_ssh_url)"
      },
    ]
  }
}
