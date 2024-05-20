output "info" {
  description = "[Output] Infra Info List"
  value = {
    vpc = {
      id = aws_vpc.create.id
      cidr_block = aws_vpc.create.cidr_block
      default_route_table_id = aws_vpc.create.default_route_table_id
      default_network_acl_id = aws_vpc.create.default_network_acl_id
      default_security_group_id = aws_vpc.create.default_security_group_id
      internet_id = aws_internet_gateway.internet.id
    }
    cidr_association_id = { for k, v in aws_vpc_ipv4_cidr_block_association.association : k => v.id }
    cidr_association_cidr = { for k, v in aws_vpc_ipv4_cidr_block_association.association : k => v.cidr_block }
    route_table_id = { for k, v in aws_route_table.create : k => v.id }
    subnet_id = { for k, v in aws_subnet.create : k => v.id }
    subnet_cidr = { for k, v in aws_subnet.create : k => v.cidr_block }
    eip_id = { for k, v in aws_eip.create : k => v.id }
    eip_public_ip = { for k, v in aws_eip.create : k => v.public_ip }
    eip_public_dns = { for k, v in aws_eip.create : k => v.public_dns }
    eip_private_ip = { for k, v in aws_eip.create : k => v.private_ip }
    eip_private_dns = { for k, v in aws_eip.create : k => v.private_dns }
    nat_public_id = { for k, v in aws_nat_gateway.create : k => v.id }
    nat_public_ip = { for k, v in aws_nat_gateway.create : k => v.public_ip }
    nat_private_ip = { for k, v in aws_nat_gateway.create : k => v.private_ip }
    acl_id = { for k, v in aws_network_acl.create : k => v.id }
    security_group_id = { for k, v in aws_security_group.create : k => v.id }
  }
}