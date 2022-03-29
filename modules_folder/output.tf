output "aws_subnet" {
    value = aws_subnet.public_subnets[0].id
    # valueTwo = aws_subnet.public_subnets[1].id
}