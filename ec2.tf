resource aws_key_pair my_key {
    key_name = "ecs-eks"
    public_key = file("ecs-eks.pub")
}

# VPC & Security Group

resource aws_default_vpc default {

}

resource aws_security_group my_security_group {
    name = "automate-ga"
    description = "this will add a TF generated security group"
    vpc_id = aws_default_vpc.default.id

    # Inbound Rules

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH Open"
    }

    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP Open"
    }

    # Outbound Rules

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
        description = "all access open outbound"
    }

    tags = {
        name = "automate-ga"
    }
}

# ec2 Instance

resource "aws_instance" "my_instance" {
    key_name = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.my_security_group.name]
    instance_type = "t3.micro"
    ami = "ami-02b8269d5e85954ef"

    root_block_device  {
        volume_size = 8
        volume_type = "gp3"
    }
    tags = {
        Name = "ecs-eks"
    }

}
