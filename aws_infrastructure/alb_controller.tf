resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    <<EOF
  clusterName: "${var.eks_cluster_name}"
  region: "${var.region}"
  vpcId: "${module.vpc.vpc_id}"
  serviceAccount:
    name: aws-load-balancer-controller
    annotations: 
      eks.amazonaws.com/role-arn: "${module.lb_role.iam_role_arn}"
  nodeSelector:
    workload: "web"
  EOF
  ]
}