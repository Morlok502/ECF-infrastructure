# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

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
