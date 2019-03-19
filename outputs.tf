output "elb_name" {
  value = "${aws_elb.hello-world.dns_name}"
}

