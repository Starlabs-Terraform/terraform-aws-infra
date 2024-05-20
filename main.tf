locals {
  tags = merge(var.info.tags,{
    Project = var.info.project
    Stage = var.info.stage
  })
  tagId = "${var.info.tag_id[0]}-${var.info.tag_id[1]}"
}
resource "aws_vpc" "create" {
  cidr_block = var.vpc_cidr
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-vpc") : "${local.tagId}-vpc" })
}
resource "aws_vpc_ipv4_cidr_block_association" "association" {
  for_each = var.vpc_cidr_association
  vpc_id = aws_vpc.create.id
  cidr_block = each.value
  depends_on = [aws_vpc.create]
}
resource "aws_internet_gateway" "internet" {
  vpc_id = aws_vpc.create.id
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-igw") : "${local.tagId}-igw" })
}
resource "aws_default_security_group" "def" {
  vpc_id = aws_vpc.create.id
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-sg-def") : "${local.tagId}-sg-def" })
}
resource "aws_default_network_acl" "def" {
  default_network_acl_id = aws_vpc.create.default_network_acl_id
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-acl-def") : "${local.tagId}-acl-def" })
}
resource "aws_default_route_table" "def" {
  default_route_table_id = aws_vpc.create.default_route_table_id
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-rt-def") : "${local.tagId}-rt-def" })
}
resource "aws_eip" "create" {
  for_each = var.eip
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-eip-${each.key}") : "${local.tagId}-eip-${each.key}", description = each.value.description })
}
resource "aws_network_acl" "create" {
  for_each = var.acl
  vpc_id = aws_vpc.create.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = each.value.egress
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-acl-${each.key}") : "${local.tagId}-acl-${each.key}" })
}
resource "aws_security_group" "create" {
  for_each = var.security_group
  vpc_id = aws_vpc.create.id
  name = var.info.tag_name_upper ? upper("${local.tagId}-sg-${each.key}") : "${local.tagId}-sg-${each.key}"
  description = each.value.description
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-sg-${each.key}") : "${local.tagId}-sg-${each.key}" })
}
resource "aws_route_table" "create" {
  for_each = var.route_table
  vpc_id = aws_vpc.create.id
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-rt-${each.key}") : "${local.tagId}-rt-${each.key}" })
}
resource "aws_route" "internet" {
  for_each = { for k, v in var.route_table : k => v if v.internet == true }
  route_table_id =  aws_route_table.create[each.key].id
  gateway_id = aws_internet_gateway.internet.id
  destination_cidr_block = each.value.internet_cidr
}
resource "aws_subnet" "create" {
  for_each = var.subnet
  vpc_id = aws_vpc.create.id
  availability_zone = "${var.info.region}${each.value.zone}"
  cidr_block = cidrsubnet(each.value.cidr_name != null ? aws_vpc_ipv4_cidr_block_association.association[each.value.cidr_name].cidr_block : var.vpc_cidr, each.value.bit, each.value.num )
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-sub-${each.key}") : "${local.tagId}-sub-${each.key}" })
}
resource "aws_route_table_association" "subnet" {
  for_each = var.subnet
  route_table_id = each.value.route_name != null ? aws_route_table.create[each.value.route_name].id : aws_vpc.create.default_route_table_id
  subnet_id = aws_subnet.create[each.key].id
  depends_on = [aws_subnet.create]
}
resource "aws_network_acl_association" "subnet" {
  for_each = var.subnet
  network_acl_id = each.value.acl_name != null ? aws_network_acl.create[each.value.acl_name].id : aws_vpc.create.default_network_acl_id
  subnet_id = aws_subnet.create[each.key].id
  depends_on = [aws_subnet.create, aws_network_acl.create]
}
resource "aws_nat_gateway" "create" {
  for_each = var.nat
  subnet_id = aws_subnet.create[each.value.subnet_name].id
  connectivity_type = each.value.connectivity_type
  allocation_id = aws_eip.create[each.value.allocation_name].id
  tags = merge(local.tags, { Name = var.info.tag_name_upper ? upper("${local.tagId}-nat-${each.key}") : "${local.tagId}-nat-${each.key}" })
  depends_on = [aws_eip.create, aws_route_table.create, aws_subnet.create]
  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }
}
resource "aws_route" "nat" {
  for_each = {for k, v in var.nat_route : k => v}
  route_table_id = aws_route_table.create[each.value.route_table_name].id
  nat_gateway_id = aws_nat_gateway.create[each.value.nat_name].id
  destination_cidr_block = each.value.route_table_cidr
  depends_on = [aws_route_table.create, aws_nat_gateway.create]
}