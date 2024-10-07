provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "terraformbucket11032003"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

# vpc for swiggy application
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "swiggy-vpc"
  }
}

# public subnet for web server
resource "aws_subnet" "web-subnet-1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "swiggy-web-subnet-1"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "swiggy-web-server-1b"
  }
}

# private subnet for app server
resource "aws_subnet" "app-subnet-1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "swiggy-app-subnet-1a"
  }
}

resource "aws_subnet" "app-subnet-2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "swiggy-app-subnet-1b"
  }
}

# private subnet for DB server
resource "aws_subnet" "db-subnet-1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "swiggy-bd-subnet-1a"
  }
}

resource "aws_subnet" "db-subnet-2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block               = "10.0.22.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "swiggy-db-subnet-1b"
  }
}

# create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "swiggy-igw"
  }
}

# create web route table
resource "aws_route_table" "web-rt" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# associate route table with subnet
resource "aws_route_table_association" "a" {
  subnet_id     = aws_subnet.web-subnet-1.id
  route_table_id = aws_route_table.web-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.web-subnet-2.id
  route_table_id = aws_route_table.web-rt.id
}

# security groups for web server
resource "aws_security_group" "webserver-sg" {
  name        = "webserver-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Web-SG"
  }
}

# create security group for app server
resource "aws_security_group" "appserver-sg" {
  name        = "appserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow traffic from web layer"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow traffic from web layer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "appserver-SG"
  }
}

# create db security group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Allow traffic from application layer"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}


# create web instances
resource "aws_instance" "webserver-1" {
  ami                   = "ami-0d1622042e957c247"
  instance_type         = "t2.micro"
  key_name              = "myKey"
  availability_zone     = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id             = aws_subnet.web-subnet-1.id
  user_data             = file("apache.sh")

  tags = {
    Name = "swiggy-web-server-1"
  }
}

resource "aws_instance" "webserver-2" {
  ami                   = "ami-0d1622042e957c247"
  instance_type         = "t2.micro"
  key_name              = "myKey"
  availability_zone     = "ap-south-1b"
  vpc_security_group_ids = [aws_security_group.webserver-sg.id]
  subnet_id             = aws_subnet.web-subnet-2.id
  user_data             = file("apache.sh")

  tags = {
    Name = "swiggy-web-server-2"
  }
}

# crearte app server 
resource "aws_instance" "appserver-1" {
  ami                   = "ami-0d1622042e957c247"
  instance_type         = "t2.micro"
  key_name              = "myKey"
  vpc_security_group_ids = [aws_security_group.appserver-sg.id]
  subnet_id             = aws_subnet.app-subnet-1.id
  availability_zone     = "ap-south-1a"
  tags = {
    Name = "swiggy-app-server-1"
  }
}

resource "aws_instance" "appserver-2" {
  ami                   = "ami-0d1622042e957c247"
  instance_type         = "t2.micro"
  key_name              = "myKey"
  vpc_security_group_ids = [aws_security_group.appserver-sg.id]
  subnet_id             = aws_subnet.app-subnet-2.id
  availability_zone     = "ap-south-1b"
  tags = {
    Name = "swiggy-app-server-2"
  }
}

# create db server
resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Raham#444555"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.id
}

# create subnet group
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.db-subnet-1.id, aws_subnet.db-subnet-2.id]

  tags = {
    Name = "my db subnet group"
  }
}

# create load balancer for swiggy 
resource "aws_lb" "external-elb" {
  name               = "SWIGGY-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver-sg.id]
  subnets            = [aws_subnet.web-subnet-1.id, aws_subnet.web-subnet-2.id]
}

resource "aws_lb_target_group" "external-elb" {
  name     = "ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group_attachment" "external-elb1" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver-1.id
  port             = 80

  depends_on = [
    aws_instance.webserver-1,
  ]
}

resource "aws_lb_target_group_attachment" "external-elb2" {
  target_group_arn = aws_lb_target_group.external-elb.arn
  target_id        = aws_instance.webserver-2.id
  port             = 80

  depends_on = [
    aws_instance.webserver-2,
  ]
}

resource "aws_lb_listener" "external-elb" {
  load_balancer_arn = aws_lb.external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-elb.arn
  }
}




output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.external-elb.dns_name
}
