# Main Terraform Configuration
# This file calls all modules to create the infrastructure

# Module: VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags
}

# Module: Internet Gateway
module "internet_gateway" {
  source = "./modules/internet_gateway"

  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags
}

# Module: Public Subnet
module "public_subnet" {
  source = "./modules/subnet"

  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone
  subnet_name       = "${var.project_name}-public-subnet"
  is_public         = true
  environment       = var.environment
  common_tags       = var.common_tags
}

# Module: Private Subnet
module "private_subnet" {
  source = "./modules/subnet"

  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  subnet_name       = "${var.project_name}-private-subnet"
  is_public         = false
  environment       = var.environment
  common_tags       = var.common_tags
}

# Module: NAT Gateway
module "nat_gateway" {
  source = "./modules/nat_gateway"

  subnet_id    = module.public_subnet.subnet_id
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags
}

# Module: Public Route Table
module "public_route_table" {
  source = "./modules/route_table"

  vpc_id              = module.vpc.vpc_id
  route_table_name    = "${var.project_name}-public-rt"
  gateway_id          = module.internet_gateway.igw_id
  nat_gateway_id      = null
  is_public           = true
  subnet_id           = module.public_subnet.subnet_id
  environment         = var.environment
  common_tags         = var.common_tags
}

# Module: Private Route Table
module "private_route_table" {
  source = "./modules/route_table"

  vpc_id              = module.vpc.vpc_id
  route_table_name    = "${var.project_name}-private-rt"
  gateway_id          = null
  nat_gateway_id      = module.nat_gateway.nat_gateway_id
  is_public           = false
  subnet_id           = module.private_subnet.subnet_id
  environment         = var.environment
  common_tags         = var.common_tags
}

# Module: Public EC2 Security Group
module "public_security_group" {
  source = "./modules/security_group"

  vpc_id             = module.vpc.vpc_id
  security_group_name = "${var.project_name}-public-sg"
  description        = "Security group for public EC2 instance"
  is_public          = true
  allowed_cidr       = var.my_ip
  environment        = var.environment
  common_tags        = var.common_tags
}

# Module: Private EC2 Security Group
module "private_security_group" {
  source = "./modules/security_group"

  vpc_id                    = module.vpc.vpc_id
  security_group_name       = "${var.project_name}-private-sg"
  description               = "Security group for private EC2 instance"
  is_public                 = false
  allowed_cidr              = var.public_subnet_cidr
  source_security_group_id  = module.public_security_group.security_group_id
  environment               = var.environment
  common_tags               = var.common_tags
}

# Module: Public EC2 Instance
module "public_ec2" {
  source = "./modules/ec2"

  ami_id              = var.ec2_ami
  instance_type       = var.ec2_instance_type
  subnet_id           = module.public_subnet.subnet_id
  security_group_ids  = [module.public_security_group.security_group_id]
  key_name            = var.ec2_key_name
  instance_name       = "${var.project_name}-public-ec2"
  is_public           = true
  environment         = var.environment
  common_tags         = var.common_tags
}

# Module: Private EC2 Instance
module "private_ec2" {
  source = "./modules/ec2"

  ami_id              = var.ec2_ami
  instance_type       = var.ec2_instance_type
  subnet_id           = module.private_subnet.subnet_id
  security_group_ids  = [module.private_security_group.security_group_id]
  key_name            = var.ec2_key_name
  instance_name       = "${var.project_name}-private-ec2"
  is_public           = false
  environment         = var.environment
  common_tags         = var.common_tags
}
