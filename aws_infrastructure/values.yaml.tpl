global:
  domain: ""  # Leave it blank to let AWS ALB assign the domain
  nodeSelector:
    workload: web
dex:
  enabled: false
notifications:
  enabled: false
configs:
  repositories:
    app-of-apps:
      url: https://github.com/gkutsarov/dynamo_apps.git
      type: git
      username: "${username}"
      password: "${password}"
  params:
    server.insecure: true
server:
  ingress:
    enabled: true
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
      alb.ingress.kubernetes.io/healthcheck-path: /healthz
    ingressClassName: alb
    hosts:
      - "*"
    paths:
      - path: /
        pathType: Prefix
    tls: []