# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table

resource "aws_vpc" "stable-click-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
      "Name", "terraform-eks-stable-click",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "stable-click-subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.stable-click-vpc.id}"

  tags = "${
    map(
      "Name", "terraform-eks-stable-click",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "stable-click-ig" {
  vpc_id = "${aws_vpc.stable-click-vpc.id}"

  tags = {
    Name = "terraform-eks-stable-click"
  }
}

resource "aws_route_table" "stable-click-rt" {
  vpc_id = "${aws_vpc.stable-click-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.stable-click-ig.id}"
  }
}

resource "aws_route_table_association" "stable-click-rta" {
  count = 2

  subnet_id      = "${aws_subnet.stable-click-subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.stable-click-rt.id}"
}