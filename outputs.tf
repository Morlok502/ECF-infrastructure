# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#
# Outputs
#

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.ecf-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.ecf.endpoint}
    certificate-authority-data: ${aws_eks_cluster.ecf.certificate_authority[0].data}
  name: ${aws_eks_cluster.ecf.arn}
contexts:
- context:
    cluster: ${aws_eks_cluster.ecf.arn}
    user: ${aws_eks_cluster.ecf.arn}
  name: ${aws_eks_cluster.ecf.arn}
current-context: ${aws_eks_cluster.ecf.arn}
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.ecf.arn}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - "${var.aws_region}"
      - eks
      - get-token
      - --cluster-name
      - "${var.cluster_name}"
      - --output
      - json
      command: aws
KUBECONFIG
}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "kubeconfig" {
  value = local.kubeconfig
}
