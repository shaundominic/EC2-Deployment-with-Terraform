resource "aws_vpc" "vpc_one" {
  cidr_block = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name="dev"
  }
}

resource "aws_subnet" "public_subnet_one" {
  vpc_id = aws_vpc.vpc_one.id
  cidr_block = "10.124.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  
  tags = {
    "dev" = "dev-public"
  }
}

resource "aws_internet_gateway" "internet_gateway_one" {
  vpc_id = aws_vpc.vpc_one.id
  
  tags = {
    "name" = "dev-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_one.id

  tags = {
    name="dev_public_rt"
  }
}


resource "aws_route" "default_route" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gateway_one.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.public_rt.id
  
}

resource "aws_security_group" "sg" {
  name="dev_sg"

  description = "dev_security_group"
  vpc_id=aws_vpc.vpc_one.id
  
  ingress = {
    from_port=0
    to_port=0
    protocol="-1"
    cidr_block=[""]
  }

  egress= {
    from_port=0
    to_port=0
    protocol="-1"
    cidr_block=["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name = "key"
  public_key = file("~/.ssh/key.pub")
}

resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami=data.aws_ami.server_ami.id
  key_name = aws_key_pair.auth.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.public_subnet_one.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size=10
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname=self.public_ip
      user="ubuntu"
      identityfile="~/.ssh/key"
    })
    interpreter = var.host_os=="windows" ? ["Powershell","-Command"] : ["bash","-c"]
    
  }

  tags = {
    name="dev-node"
  }
}