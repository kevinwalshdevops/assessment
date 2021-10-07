resource "aws_db_instance" "default" {
  allocated_storage    = 10
  max_allocated_storage = 100
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = var.dbsubgrpname
  depends_on = [
    aws_db_subnet_group.default
  ]
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}
#Jenkins 
resource "aws_instance" "jenkins-instance" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = "t2.medium"
  key_name = "aws"
  vpc_security_group_ids = [aws_security_group.sg_allow_ssh_jenkins.id, aws_security_group.instances.id]
  subnet_id          = aws_subnet.public_subnet.id
  #name            = "${var.name}"
  user_data = file("jenkins.sh")

  associate_public_ip_address = true
  tags = {
    Name = "Jenkins-Instance"
  }
}
//bastion
data "aws_ami" "aws_linux_2" {
  count       = 1
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^amzn2-ami-hvm-2.0.*"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
resource "aws_launch_configuration" "bastion" {
  name_prefix = "${var.name_prefix}launch-config-"
  image_id    = var.custom_ami != "" ? var.custom_ami : data.aws_ami.aws_linux_2[0].image_id
  # A t2.nano should be perfectly sufficient for a simple bastion host
  instance_type               = "t2.nano"
  associate_public_ip_address = false
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.bastion_host_profile.name
  key_name                    = "aws"

  security_groups = [aws_security_group.bastion.id]

  user_data = templatefile("${path.module}/init.sh", {
    region      = var.region
    bucket_name = aws_s3_bucket.bucket_2.bucket
  })

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "bastion" {
  name_prefix          = "${var.name_prefix}asg-"
  launch_configuration = aws_launch_configuration.bastion.name
  max_size             = 3
  min_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]

  default_cooldown          = 180
  health_check_grace_period = 180
  health_check_type         = "EC2"

  target_group_arns = [
    aws_lb_target_group.bastion_default.arn,
  ]

  termination_policies = [
    "OldestLaunchConfiguration",
  ]

  dynamic tag {
    for_each = {"Name" = "${var.name_prefix}asg"}
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_lb" "bastion" {
  name_prefix = "${var.name_prefix}lb"
  internal    = false

  subnets = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  load_balancer_type = "network"
  tags               = {
      Name = "lb-bastion"
  }
}

resource "aws_lb_target_group" "bastion_default" {
  vpc_id = aws_vpc.main.id

  port        = var.external_ssh_port
  protocol    = "TCP"
  target_type = "instance"

  health_check {
    port     = "traffic-port"
    protocol = "TCP"
  }

  tags = {
      Name = "lb-tg-grp"
  }
}

resource "aws_lb_listener" "bastion_ssh" {
  load_balancer_arn = aws_lb.bastion.arn
  port              = var.external_ssh_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.bastion_default.arn
    type             = "forward"
  }
}
data "aws_iam_policy_document" "bastion_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "${var.name_prefix}bastion"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_role.json
}

data "aws_iam_policy_document" "bastion_policy" {
  # Allow downloading of user SSH public keys
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket_2.arn}"]
    effect    = "Allow"
  }

  # Allow listing SSH public keys
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bucket_2.arn]
  }
}

resource "aws_iam_policy" "bastion" {
  name_prefix = "${var.name_prefix}bastion"
  policy      = data.aws_iam_policy_document.bastion_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_given_policy" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion.arn
}

resource "aws_iam_instance_profile" "bastion_host_profile" {
  name_prefix = "${var.name_prefix}bastion-profile"
  role        = aws_iam_role.bastion.name
}
output "instances_security_group_id" {
  value = aws_security_group.instances.id
}

output "bastion_dns_name" {
  value = aws_lb.bastion.dns_name
}

output "ssh_keys_bucket" {
  value = aws_s3_bucket.bucket_2.bucket
}