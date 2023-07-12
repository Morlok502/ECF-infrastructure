# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "aws_region" {
  default = "eu-west-3"
}

variable "cluster_name" {
  default = "studi-ecf-eks-"
  type    = string
}
