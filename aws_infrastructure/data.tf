data "aws_subnet" "public_subnet_1" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.1.0/24"]
  }
  depends_on = [module.vpc]
}

data "aws_subnet" "public_subnet_2" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.2.0/24"]
  }
  depends_on = [module.vpc]
}

data "aws_subnet" "public_subnet_3" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.3.0/24"]
  }
  depends_on = [module.vpc]
}