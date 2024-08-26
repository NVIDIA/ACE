
resource "aws_s3_object" "install_aws_cli" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-aws-cli.sh", local.name)
  content = file("${path.module}/config/install-aws-cli.sh")
}

resource "aws_s3_object" "coturn_server_env" {
  bucket = var.base_config.config_bucket
  key    = format("%s/coturn-server-env.sh", local.name)
  content = templatefile("${path.module}/config/coturn-server-env.sh.tpl", {
    name   = local.name
    coturn = var.coturn_settings
  })
}

resource "aws_s3_object" "setup_coturn_server" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-coturn-server.sh", local.name)
  content = file("${path.module}/config/setup-coturn-server.sh")
}