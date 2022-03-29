module "vpc_creation" {
    source = "./modules_folder"
    vpc_cidr_block = var.vpc_cidr_block
    public_subnet_cidrs = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    availability_zone = var.availability_zone
    ami_id = var.ami_id
}