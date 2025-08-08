provider "aws" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

## subnets
#
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  depends_on = [
    aws_internet_gateway.main,
    aws_eip.nat_eip,
    aws_subnet.public,
  ]
}

resource "aws_route_table" "public" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_internet_gateway.main]
}
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

# --------------------------
# Azure equivalent resources
# --------------------------

provider "azurerm" {
  features {}
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "phoenix-ctf-rg"
  location = "UK South"
}

# Virtual Network (VPC equivalent)
resource "azurerm_virtual_network" "main" {
  name                = "phoenix-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet (Subnet equivalent)
resource "azurerm_subnet" "public" {
  name                 = "phoenix-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

output "azure_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "azure_vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "azure_subnet_id" {
  value = azurerm_subnet.public.id
}
