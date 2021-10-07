resource "aws_security_group" "sg_allow_ssh_jenkins" {
  name        = "allow_ssh_jenkins"
  description = "Allow SSH and Jenkins inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

output "jenkins_ip_address" {
  value = aws_instance.jenkins-instance.public_dns
}

//bastion host
resource "aws_security_group" "bastion" {
  description = "Enable SSH access to the bastion host from external via SSH port"
  name        = "${var.name_prefix}main"
  vpc_id      = aws_vpc.main.id

  tags = {
      Name = "batstion-sg"
  }

  # Incoming traffic from the internet. Only allow SSH connections
  ingress {
    from_port   = var.external_ssh_port
    to_port     = var.external_ssh_port
    protocol    = "TCP"
    cidr_blocks = var.external_allowed_cidrs
  }

  # Outgoing traffic - anything VPC only
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # Plus allow HTTP(S) internet egress for yum updates
  egress {
    description = "Outbound TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instances" {
  description = "Apply this group to specific instances to allow SSH ingress from the bastion"
  name        = "${var.name_prefix}instances"
  vpc_id      = aws_vpc.main.id

  tags = {
      Name = "instance-sg"
  }

  # Incoming traffic from the internet. Only allow SSH connections
  ingress {
    from_port       = var.internal_ssh_port
    to_port         = var.internal_ssh_port
    protocol        = "TCP"
    security_groups = [aws_security_group.bastion.id]
  }
}