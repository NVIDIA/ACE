
locals {
  name = format("%s-coturn", var.name)
  coturn_instance_details = {
    instance_type    = "t3.micro"
    root_volume_type = "gp3"
    root_volume_size = 50
  }

  coturn_ami_name_defaults = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  coturn_ami_name          = var.coturn_ami_name == null ? local.coturn_ami_name_defaults : var.coturn_ami_name
  coturn_ami_lookup = {
    owners = ["099720109477"] # Canonical
    filters = [
      {
        name   = "name"
        values = [local.coturn_ami_name]
      },
      {
        name   = "virtualization-type"
        values = ["hvm"]
      }
    ]
  }
  config_scripts = [
    {
      exec = "bash"
      path = aws_s3_object.install_aws_cli.key
      hash = sha256(aws_s3_object.install_aws_cli.content)
    },
    {
      exec = "source"
      path = aws_s3_object.coturn_server_env.key
      hash = sha256(aws_s3_object.coturn_server_env.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_coturn_server.key
      hash = sha256(aws_s3_object.setup_coturn_server.content)
    }
  ]
}