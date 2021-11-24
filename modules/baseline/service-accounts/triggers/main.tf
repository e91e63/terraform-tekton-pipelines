terraform {
  experiments = [module_variable_optional_attrs]
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
  }
  required_version = "~> 1"
}

locals {
  conf = defaults(var.conf, {})
}

resource "kubernetes_cluster_role" "main" {
  metadata {
    annotations = {}
    labels = {
      "app.kubernetes.io/name" = local.conf.name
    }
    name = local.conf.name
  }
  rule {
    api_groups = [
      "triggers.tekton.dev",
    ]
    non_resource_urls = []
    resource_names    = []
    resources = [
      "clustertriggerbindings",
      "clusterinterceptors",
    ]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
}

resource "kubernetes_cluster_role_binding" "main" {
  metadata {
    annotations = {}
    labels = {
      "app.kubernetes.io/name" = local.conf.name
    }
    name = local.conf.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_role.main.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.main.metadata[0].name
    namespace = local.conf.namespace
  }
}

resource "kubernetes_role" "main" {
  metadata {
    annotations = {}
    labels = {
      "app.kubernetes.io/name" = local.conf.name
    }
    name      = local.conf.name
    namespace = local.conf.namespace
  }
  rule {
    api_groups = [
      "triggers.tekton.dev",
    ]
    resource_names = []
    resources = [
      "eventlisteners",
      "triggerbindings",
      "triggertemplates",
      "triggers",
    ]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
  rule {
    api_groups     = [""]
    resource_names = []
    resources = [
      "configmaps",
    ]
    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
  rule {
    api_groups = [
      "tekton.dev",
      "tekton.dev/v1beta1",
    ]
    resource_names = []
    resources = [
      "pipelineruns",
      "pipelineresources",
      "taskruns",
    ]
    verbs = [
      "create",
    ]
  }
  rule {
    api_groups     = [""]
    resource_names = []
    resources = [
      "serviceaccounts",
    ]
    verbs = [
      "impersonate",
    ]
  }
  rule {
    api_groups = [
      "policy",
    ]
    resource_names = [
      local.conf.name,
    ]
    resources = [
      "podsecuritypolicies",
    ]
    verbs = [
      "use",
    ]
  }
}

resource "kubernetes_role_binding" "main" {
  metadata {
    annotations = {}
    labels = {
      "app.kubernetes.io/name" = local.conf.name
    }
    name      = local.conf.name
    namespace = local.conf.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.main.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.main.metadata[0].name
    namespace = local.conf.namespace
  }
}

resource "kubernetes_service_account" "main" {
  metadata {
    annotations = {}
    labels = {
      "app.kubernetes.io/name" = local.conf.name
    }
    name      = local.conf.name
    namespace = local.conf.namespace
  }
}
