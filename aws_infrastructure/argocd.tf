resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  create_namespace = true

 values = [
    templatefile("${path.module}/values.yaml.tpl", {
      username = kubernetes_secret.argocd_repo_secret.data["username"]
      password = kubernetes_secret.argocd_repo_secret.data["token"]
    })
  ]
}

resource "helm_release" "argocd-apps" {
  depends_on = [helm_release.argocd]
  name = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argocd-apps"
  namespace = "argocd"

  values = [
    <<EOT
    applications:
      app-of-apps:
        namespace: argocd
        project: default
        source:
          repoURL: https://github.com/gkutsarov/dynamo_apps
          targetRevision: main
          path: bootstrap
        destination:
          server: https://kubernetes.default.svc
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
    EOT
  ]
}