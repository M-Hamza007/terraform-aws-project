# data "aws_availability_zones" "zones" {
# 	names = var.availability_zone
# }

resource "aws_vpc" "vpc" {
    cidr_block       = var.vpc_cidr_block
    instance_tenancy = "default"
    tags = {
    Name = "practice_vpc"
    }
}

resource "aws_internet_gateway" "public_gw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
    Name = "internet gateway"
}
}

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs)
    vpc_id     = aws_vpc.vpc.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zone[count.index]
    tags = {
    Name = "public subnet ${count.index}"
    }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)
    vpc_id     = aws_vpc.vpc.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zone[count.index]
    tags = {
    Name = "public subnet ${count.index}"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.public_gw.id
    }
    tags = {
        Name = "public route table"
    }
}

resource "aws_eip" "NAT_instance" {
    count = length(var.public_subnet_cidrs)
    depends_on = [aws_internet_gateway.public_gw]
    vpc      = true
}

resource "aws_nat_gateway" "nat_gw" {
    count = length(var.public_subnet_cidrs)
    allocation_id = aws_eip.NAT_instance[count.index].id
    subnet_id     = aws_subnet.public_subnets[count.index].id
    depends_on = [aws_internet_gateway.public_gw]
    tags = {
        Name = "NAT in public subnet ${count.index}"
    }
}

resource "aws_route_table" "private_route_table" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gw[count.index].id
    }
    tags = {
        Name = "private route table"
    }
}

resource "aws_route_table_association" "public_subnet_association" {
    count = length(var.public_subnet_cidrs)
    subnet_id      = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
    count = length(var.private_subnet_cidrs)
    subnet_id      = aws_subnet.private_subnets[count.index].id
    route_table_id = aws_route_table.private_route_table[count.index].id
}

# to create security group - to be attach Load Balancer
resource "aws_security_group" "demoSG1" {
    name        = "Demo Security Group"
    description = "Demo Module"
    vpc_id      = aws_vpc.vpc.id
    # Inbound Rules
    # HTTP access from anywhere
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # HTTPS access from anywhere
    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }  # SSH access from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Outbound Rules
    # opening outbound connection for all the ports and IPs.
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    }


# to create Load Balancer
resource "aws_alb" "demo_lb" {
    name = "demo-lb"
    load_balancer_type = "application"
    ip_address_type = "ipv4"
    internal = false
    enable_deletion_protection  = false

    security_groups = [
        "${aws_security_group.demoSG1.id}"
    ]

    subnets = [
        aws_subnet.public_subnets[0].id,
        aws_subnet.public_subnets[1].id
    ]
    tags = {
        Name = "my-test-alb"
    }
}    


# to create Launch Configuration
resource "aws_launch_configuration" "ubuntu" {
    name_prefix = "ubuntu-"
    image_id = var.ami_id
    instance_type = "t2.micro"
    security_groups = [aws_security_group.demoSG1.id]
    associate_public_ip_address = true
    # user_data = "${file("data.sh")}"
    # user_data = file("${path.module}/data.sh")
    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install httpd
                sudo apt-get install nginx -y
                sudo echo "Hello, from terraform!!" >/var/www/html/index.nginx-debian.html
                sudo service httpd start
                chkconfig httpd on
                EOF
    # to create new instances from a new launch configuration before destroying the old ones
    lifecycle {
        create_before_destroy = true
    }
}


# instance target group
resource "aws_alb_target_group" "demo_tg" {
    name     = "demo-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.vpc.id
    target_type = "instance"
    health_check {
        healthy_threshold = 5
        unhealthy_threshold = 2
        timeout = 5
        interval = 10
        port = 80
        protocol = "HTTP"
        path = "/"
    }
}

resource "aws_alb_listener" "listener_http" {
    load_balancer_arn = aws_alb.demo_lb.arn
    port              = "80"
    protocol          = "HTTP"
    default_action {
        target_group_arn = aws_alb_target_group.demo_tg.arn
        type             = "forward"
    }
}

# to create auto scaling group
resource "aws_autoscaling_group" "demo_ASG" {
    name = "demo_ASG"
    launch_configuration = aws_launch_configuration.ubuntu.name
    min_size             = 2
    desired_capacity     = 4
    max_size             = 6
    health_check_type    = "ELB"
    target_group_arns = [ aws_alb_target_group.demo_tg.id ]
    vpc_zone_identifier  = [
        aws_subnet.private_subnets[0].id,
        aws_subnet.private_subnets[1].id
    ]
    # Required to redeploy without an outage.
    lifecycle {
        create_before_destroy = true
    }
    tag {
        key                 = "Name"
        value               = "demo-asg"
        propagate_at_launch = true
    }
}

# resource "aws_alb_target_group_attachment" "test" {
#     target_group_arn = aws_alb_target_group.demo_tg.arn
#     target_id        = aws_instance.test.id
#     port             = 80
# }

# resource "aws_alb_target_group_attachment" "test" {
#     target_group_arn = aws_alb_target_group.demo_tg.arn
#     target_id        = aws_instance.test.id
#     port             = 80
# }

# resource "aws_alb_target_group_attachment" "test" {
#     target_group_arn = aws_alb_target_group.demo_tg.arn
#     target_id        = aws_instance.test.id
#     port             = 80
# }

# resource "aws_alb_target_group_attachment" "test" {
#     target_group_arn = aws_alb_target_group.demo_tg.arn
#     target_id        = aws_instance.test.id
#     port             = 80
# }