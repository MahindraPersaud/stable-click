# VPC Resources
#  VPC
#  Subnets
#  Internet Gateway
#  Route Table

resource "aws_vpc" "halfclick-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
      "Name", "terraform-eks-halfclick-vpc",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "halfclick-subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.halfclick-vpc.id}"

  tags = "${
    map(
      "Name", "terraform-eks-halfclick-subnet",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "halfclick-ig" {
  vpc_id = "${aws_vpc.halfclick-vpc.id}"

  tags = {
    Name = "terraform-eks-halfclick-ig"
  }
}

resource "aws_route_table" "halfclick-rt" {
  vpc_id = "${aws_vpc.halfclick-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.halfclick-ig.id}"
  }
}

resource "aws_route_table_association" "halfclick-rta" {
  count = 2

  subnet_id      = "${aws_subnet.halfclick-subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.halfclick-rt.id}"
}