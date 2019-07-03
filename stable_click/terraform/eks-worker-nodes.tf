# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances

resource "aws_iam_role" "stable-click-worker-iam" {
  name = "terraform-eks-stable-click-worker"

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

resource "aws_iam_role_policy_attachment" "stable-click-worker-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.stable-click-worker-iam.name}"
}

resource "aws_iam_role_policy_attachment" "stable-click-worker-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.stable-click-worker-iam.name}"
}

resource "aws_iam_role_policy_attachment" "stable-click-worker-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.stable-click-worker-iam.name}"
}

resource "aws_iam_instance_profile" "stable-click-worker-iam-ip" {
  name = "terraform-eks-stable-click"
  role = "${aws_iam_role.stable-click-worker-iam.name}"
}

resource "aws_security_group" "stable-click-worker-sg" {
  name        = "terraform-eks-stable-click-worker"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.stable-click-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-stable-click-worker",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "stable-click-worker-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.stable-click-worker-sg.id}"
  source_security_group_id = "${aws_security_group.stable-click-worker-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "stable-click-worker-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.stable-click-worker-sg.id}"
  source_security_group_id = "${aws_security_group.stable-click-cluster-sg.id}"
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.stable-click-cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
locals {
  stable-click-worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.stable-click-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.stable-click-cluster.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "stable-click-worker-lc" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.stable-click-worker-iam-ip.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "t2.micro"
  name_prefix                 = "terraform-eks-stable-click"
  security_groups             = ["${aws_security_group.stable-click-worker-sg.id}"]
  user_data_base64            = "${base64encode(local.stable-click-worker-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "stable-click-worker-asg" {
  desired_capacity     = 6
  launch_configuration = "${aws_launch_configuration.stable-click-worker-lc.id}"
  max_size             = 10
  min_size             = 1
  name                 = "terraform-eks-stable-click"
  vpc_zone_identifier  = ["${aws_subnet.stable-click-subnet.*.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-stable-click"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}