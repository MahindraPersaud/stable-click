# EKS Worker Nodes Resources
#  IAM role allowing Kubernetes actions to access other AWS services
#  EC2 Security Group to allow networking traffic
#  Data source to fetch latest EKS worker AMI
#  AutoScaling Launch Configuration to configure worker instances
#  AutoScaling Group to launch worker instances

resource "aws_iam_role" "halfclick-worker-iam" {
  name = "terraform-eks-halfclick-worker-iam"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "halfclick-worker-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.halfclick-worker-iam.name}"
}

resource "aws_iam_role_policy_attachment" "halfclick-worker-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.halfclick-worker-iam.name}"
}

resource "aws_iam_role_policy_attachment" "halfclick-worker-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.halfclick-worker-iam.name}"
}

resource "aws_iam_instance_profile" "halfclick-worker-ip" {
  name = "terraform-eks-halfclick-worker-ip"
  role = "${aws_iam_role.halfclick-worker-iam.name}"
}

resource "aws_security_group" "halfclick-worker-sg" {
  name        = "terraform-eks-halfclick-worker-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.halfclick-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-halfclick-worker-sg",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "halfclick-worker-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.halfclick-worker-sg.id}"
  source_security_group_id = "${aws_security_group.halfclick-worker-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "halfclick-worker-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.halfclick-worker-sg.id}"
  source_security_group_id = "${aws_security_group.halfclick-cluster-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.halfclick-cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
locals {
  halfclick-worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.halfclick-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.halfclick-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "halfclick-worker-lc" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.halfclick-worker-ip.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "m4.large"
  name_prefix                 = "terraform-eks-halfclick-worker"
  security_groups             = ["${aws_security_group.halfclick-worker-sg.id}"]
  user_data_base64            = "${base64encode(local.halfclick-worker-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hakfclick-worker-as" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.halfclick-worker-lc.id}"
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-halfclick-worker-as"
  vpc_zone_identifier  = ["${aws_subnet.halfclick-subnet.*.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-halfclick-worker-as"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}