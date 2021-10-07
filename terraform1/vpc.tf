resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-2b"
  cidr_block = var.private_sub_cidr
}
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-2c"
  cidr_block = var.public_sub_cidr
  map_public_ip_on_launch  = true
}
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.one.id
  subnet_id     = aws_subnet.public_subnet.id
  connectivity_type = "public"
  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.example]
}
resource "aws_eip" "one" {
  vpc                       = true
  associate_with_private_ip = "10.0.1.13"
  depends_on                = [aws_internet_gateway.example]
}
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.main.id
}
resource "aws_db_subnet_group" "default" {
  name       = var.dbsubgrpname
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "${var.environment_1}-Public-RouteTable"
  }
}
resource "aws_route_table" "private-route-table" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "${var.environment_1}-Private-RouteTable"
  }
}
resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = "${aws_route_table.private-route-table.id}"
  subnet_id      = "${aws_subnet.private_subnet.id}"
}
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = "${aws_route_table.public-route-table.id}"
  subnet_id      = "${aws_subnet.public_subnet.id}"
}
resource "aws_route" "nat-gw-route" {
  route_table_id         = "${aws_route_table.private-route-table.id}"
  nat_gateway_id         = "${aws_nat_gateway.example.id}"
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = "${aws_route_table.public-route-table.id}"
  gateway_id             = "${aws_internet_gateway.example.id}"
  destination_cidr_block = "0.0.0.0/0"
}