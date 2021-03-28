provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"  

}
#### IAM Role for S3 Access #####
#S3_access
resource "aws_iam_instance_profile" "S3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

## Role Policy ##
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
           "Effect": "Allow",
           "Action": "s3:*",
           "Resource": "*"
       }
    ]
}
EOF
}

## Role Creation ##
resource = "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"
  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

### VPC Creation ###
resource "aws_vpc" "wp_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = ture
  enable_dns_support = ture
  ### This is useful when we create our private zones, this will allow us to reference our database which will be storeded in private zone
  tags {
     Name = "wp_vpc"
  }

}

### IGW Creation "
resource "aws_internet_gateway" 'wp_internet_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  tags {
    Name = "wp_igw"
  }
}

### Create Route Table ###
# ---------- Public Route --------- #
resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}" 
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet_gateway.id}"  
  }

  tags {
      Name = "wp_public"
  }
}

# ---------- Private Route --------- #
resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"  
  tags {
      Name = "wp_private"
  }
}

### Subnet Creation ###
