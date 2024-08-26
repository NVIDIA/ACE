
resource "aws_s3_object" "mount_data_disk" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/mount-data-disk.sh", local.name)
  content = file("${path.module}/config/mount-data-disk.sh")
}

resource "aws_s3_object" "install_cns" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-cns.sh", local.name)
  content = file("${path.module}/config/install-cns.sh")
}

resource "aws_s3_object" "install_aws_cli" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/install-aws-cli.sh", local.name)
  content = file("${path.module}/config/install-aws-cli.sh")
}

resource "aws_s3_object" "rp_env" {
  bucket = var.base_config.config_bucket
  key    = format("%s/rp-env.sh", local.name)
  content = templatefile("${path.module}/config/rp-env.sh.tpl", {
    name        = local.name
    ngc_api_key = var.ngc_api_key
    chart_url   = local.chart_url
    cns_commit  = local.rp_settings.cns_settings.cns_commit
    cns_version = local.rp_settings.cns_settings.cns_version
  })
}

resource "aws_s3_object" "setup_rp_secrets" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-rp-secrets.sh", local.name)
  content = file("${path.module}/config/setup-rp-secrets.sh")
}

resource "aws_s3_object" "setup_rp_chart" {
  bucket  = var.base_config.config_bucket
  key     = format("%s/setup-rp-chart.sh", local.name)
  content = file("${path.module}/config/setup-rp-chart.sh")
}

locals {
  config_scripts = [
    {
      exec = "bash"
      path = aws_s3_object.mount_data_disk.key
      hash = sha256(aws_s3_object.mount_data_disk.content)
    },
    {
      exec = "source"
      path = aws_s3_object.rp_env.key
      hash = sha256(aws_s3_object.rp_env.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.install_cns.key
      hash = sha256(aws_s3_object.install_cns.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.install_aws_cli.key
      hash = sha256(aws_s3_object.install_aws_cli.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_rp_secrets.key
      hash = sha256(aws_s3_object.setup_rp_secrets.content)
    },
    {
      exec = "bash"
      path = aws_s3_object.setup_rp_chart.key
      hash = sha256(aws_s3_object.setup_rp_chart.content)
    }
  ]
}