variable "info" {
  description = "[Required] Project Info"
  type = object({
    project = optional(string, "pj")
    stage = optional(string, "stg")
    tag_id = tuple([string, string])
    region = optional(string, "ap-northeast-2")
    tags = optional(map(string), {})
    tag_name_upper = optional(bool, false)
  })
}
variable "vpc_cidr" {
  description = "[Required] VPC Cidr (String)"
  type = string
}
variable "vpc_cidr_association" {
  description = "[Optional] VPC Cidr Association - List"
  type = map(string)
  default = {}
}
variable "acl" {
  description = "[Required] Network acl - List"
  type = map(object({
    ingress = optional(list(object({
      protocol   = optional(string, "tcp")
      rule_no    = optional(number ,100)
      action     = optional(string, "allow")
      cidr_block = optional(string, "0.0.0.0/0")
      from_port  = optional(number, 0)
      to_port    = optional(number, 0)
    })),[])
    egress = optional(list(object({
      protocol   = optional(string, "tcp")
      rule_no    = optional(number ,100)
      action     = optional(string, "allow")
      cidr_block = optional(string, "0.0.0.0/0")
      from_port  = optional(number, 0)
      to_port    = optional(number, 0)
    })),[])
  }))
  default = {}
}
variable "security_group" {
  description = "[Required] Security Group - List"
  type = map(object({
    outbound = optional(bool, null)
    description = optional(string, null)
  }))
}
variable "route_table" {
  description = "[Required] Route Table - List"
  type = map(object({
    internet = optional(bool, false)
    internet_cidr = optional(string, "0.0.0.0/0")
  }))
}
variable "subnet" {
  description = "[Required] Subnet - List"
  type = map(object({
    cidr_name = optional(string, null)
    route_name = optional(string, null)
    bit = optional(number, 8)
    num = optional(number, 0)
    zone = optional(string, "a")
    acl_name = optional(string, null)
  }))
}
variable "eip" {
  description = "[Optional] Eip - List"
  type = map(object({
    description = optional(string, null)
  }))
  default = {}
}
variable "nat" {
  description = "[Optional] Nat Gateway - List"
  type = map(object({
    connectivity_type = optional(string, "public")
    subnet_name = string
    allocation_name = string
  }))
  default = {}
}
variable "nat_route" {
  description = "[Optional] Nat Gateway in Route Table - List"
  type = list(object({
    nat_name = string
    route_table_name = string
    route_table_cidr = optional(string, "0.0.0.0/0")
  }))
  default = []
}