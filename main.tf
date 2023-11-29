# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

################################################################################
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
################################################################################

resource "aws_vpc" "ecf" {
  cidr_block = "10.0.0.0/16"

  tags = tomap({
    "Name"                                      = "studi-eks-ecf-node",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_subnet" "ecf" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.ecf.id

  tags = tomap({
    "Name"                                      = "studi-eks-ecf-node",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_subnet" "ecf_private" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index + 10}.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.ecf.id

  tags = tomap({
    "Name"                                      = "studi-eks-ecf-node-private_subnet",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_internet_gateway" "ecf" {
  vpc_id = aws_vpc.ecf.id

  tags = {
    Name = "studi-eks-ecf"
  }
}

resource "aws_route_table" "ecf" {
  vpc_id = aws_vpc.ecf.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecf.id
  }
}

resource "aws_route_table_association" "ecf" {
  count = 2

  subnet_id      = aws_subnet.ecf[count.index].id
  route_table_id = aws_route_table.ecf.id
}


################################################################################
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
################################################################################

resource "aws_iam_role" "ecf-cluster" {
  name = "studi-eks-ecf-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecf-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.ecf-cluster.name
}

resource "aws_iam_role_policy_attachment" "ecf-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.ecf-cluster.name
}

resource "aws_security_group" "ecf-cluster" {
  name        = "studi-eks-ecf-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.ecf.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "studi-eks-ecf"
  }
}

resource "aws_security_group_rule" "ecf-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ecf-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "ecf" {
  name     = var.cluster_name
  role_arn = aws_iam_role.ecf-cluster.arn
  version  = "1.27"

  vpc_config {
    security_group_ids = [aws_security_group.ecf-cluster.id]
    subnet_ids         = aws_subnet.ecf[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecf-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.ecf-cluster-AmazonEKSVPCResourceController,
  ]
}


################################################################################
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
################################################################################

resource "aws_iam_role" "ecf-node" {
  name = "studi-eks-ecf-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecf-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ecf-node.name
}

resource "aws_iam_role_policy_attachment" "ecf-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ecf-node.name
}

resource "aws_iam_role_policy_attachment" "ecf-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ecf-node.name
}

# Policy pour envoyer les logs à cloudwatch
resource "aws_iam_role_policy_attachment" "ecf-node-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ecf-node.name
}

resource "aws_eks_addon" "cloudwatch" {
  addon_name   = "amazon-cloudwatch-observability"
  cluster_name = "studi-ecf-eks-cluster"
}

resource "aws_eks_node_group" "ecf" {
  cluster_name    = aws_eks_cluster.ecf.name
  node_group_name = "ecf"
  node_role_arn   = aws_iam_role.ecf-node.arn
  subnet_ids      = aws_subnet.ecf[*].id
  disk_size       = 10
  instance_types  = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecf-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ecf-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ecf-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

################################################################################
# Workstation External IP
#
# This configuration is not required and is
# only provided as an example to easily fetch
# the external IP of your local workstation to
# configure inbound EC2 Security Group access
# to the Kubernetes cluster.
################################################################################

data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

# Override with variable or hardcoded value if necessary
locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
}
