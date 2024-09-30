module "create_s3_bucket" {
  source = "./modules/aws_s3_bucket"
  bucket_name = "depi-189-tf-s3-bucket-28734637456"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "depi-189-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}