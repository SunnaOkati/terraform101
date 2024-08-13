# Create a VPC
resource "aws_vpc" "syd-vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "syd-public-subnet" {
  vpc_id                  = aws_vpc.syd-vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-2a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "syd-internet-gateway" {
  vpc_id = aws_vpc.syd-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "syd-public-rt" {
  vpc_id = aws_vpc.syd-vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.syd-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.syd-internet-gateway.id
}

resource "aws_route_table_association" "syd-public-assoc" {
  subnet_id      = aws_subnet.syd-public-subnet.id
  route_table_id = aws_route_table.syd-public-rt.id
}

resource "aws_security_group" "syd-sg" {
  name        = "dev-sg"
  description = "Dev security group"
  vpc_id      = aws_vpc.syd-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "syd-auth" {
  key_name   = "${var.key_pair_file}"
  public_key = file("~/.ssh/${var.key_pair_file}.pub")
}

resource "aws_instance" "syd-node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.syd-auth.id
  vpc_security_group_ids = [aws_security_group.syd-sg.id]
  subnet_id              = aws_subnet.syd-public-subnet.id
  user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "syd-node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
        hostname = self.public_ip,
        user = "ec2-user",
        identityfile = "~/.ssh/${var.key_pair_file}"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }
}