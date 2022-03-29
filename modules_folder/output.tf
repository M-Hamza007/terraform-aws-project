output "aws_public_subnet" {
    value = aws_subnet.public_subnets.*.id
}

output "aws_private_subnet" {
    value = aws_subnet.private_subnets.*.id
}

output "public_subnet1" {
    value = "${element(aws_subnet.public_subnets.*.id, 1 )}"
}

output "public_subnet2" {
    value = "${element(aws_subnet.public_subnets.*.id, 2 )}"
}

output "private_subnet1" {
    value = "${element(aws_subnet.private_subnets.*.id, 1 )}"
}

output "private_subnet2" {
    value = "${element(aws_subnet.private_subnets.*.id, 2 )}"
}
output "aws_vpc_id" {
    value = aws_vpc.vpc.id
}

output "aws_security_group" {
    value = aws_security_group.demoSG1.id
}

# data "aws_instances" "test" {
#     instance_tags = {
#     SomeTag = "SomeValue"
#     }

#     instance_state_names = ["running", "stopped"]
# }

# output ids {
#     value = data.aws_instances.test.ids
# }