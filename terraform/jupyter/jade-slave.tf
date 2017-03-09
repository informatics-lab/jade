variable worker-name {}

data "template_file" "slave-bootstrap" {
    template            = "${file("bootstrap/slave-bootstrap.sh")}"

    vars = {
      jademaster_private_ip = "${aws_instance.jademaster.private_ip}"
    }
}

resource "aws_security_group" "jadeslave" {
  name = "${var.worker-name}"
  description = "Allow jade traffic"

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_from_master" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"

    security_group_id = "${aws_security_group.jadeslave.id}"
    source_security_group_id = "${aws_security_group.jademaster.id}"
}

resource "aws_security_group_rule" "allow_slave_monitoring" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"

    security_group_id = "sg-11e34c75" # Magic id for persistent monitoring stack
    source_security_group_id = "${aws_security_group.jadeslave.id}"
}

resource "aws_launch_configuration" "notebook-slaves" {
    name = "${var.worker-name}"
    image_id = "ami-f9dd458a"
    instance_type = "m3.xlarge"
    key_name = "gateway"
    iam_instance_profile  = "jade-secrets"
    security_groups = ["default", "${aws_security_group.jadeslave.name}"]
    spot_price = "0.3"
    user_data = "${data.template_file.slave-bootstrap.rendered}"

    root_block_device = {
      volume_size = 20
    }
}

resource "aws_autoscaling_group" "notebook-slaves" {
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  name = "${var.worker-name}s"
  max_size = 1
  min_size = 1
  desired_capacity = 1
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.notebook-slaves.name}"

  tag {
    key = "Name"
    value = "${var.worker-name}"
    propagate_at_launch = true
  }
}
