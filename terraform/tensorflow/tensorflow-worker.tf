variable worker-name {}

data "template_file" "tfworker-bootstrap" {
    template            = "${file("${path.module}/../../bootstrap/tensorflow.sh")}"
}

resource "aws_security_group" "tfworker" {
  name = "${var.worker-name}"

  ingress {
      from_port         = 8754
      to_port           = 8754
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
      from_port         = 6006
      to_port           = 6006
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
      from_port         = 2222
      to_port           = 2222
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
      from_port         = 2223
      to_port           = 2223
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "tf-workers" {
    name = "${var.worker-name}"
    image_id = "ami-ed82e39e"
    instance_type = "g2.2xlarge"
    key_name = "gateway"
    security_groups = ["default", "${aws_security_group.tfworker.name}"]
    spot_price = "0.65"
    user_data = "${data.template_file.tfworker-bootstrap.rendered}"

    root_block_device = {
      volume_size = 20
    }
}

resource "aws_autoscaling_group" "tf-workers" {
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  name = "${var.worker-name}s"
  max_size = 2
  min_size = 1
  desired_capacity = 2
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.tf-workers.name}"

  tag {
    key = "Name"
    value = "${var.worker-name}"
    propagate_at_launch = true
  }
}