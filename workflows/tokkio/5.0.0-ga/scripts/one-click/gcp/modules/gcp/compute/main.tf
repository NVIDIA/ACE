resource "google_compute_address" "default" {
  provider = google

  for_each = var.compute_addresses

  name               = coalesce(each.value.name, each.key)
  address            = each.value.address
  address_type       = each.value.address_type
  description        = each.value.description
  purpose            = each.value.purpose
  network_tier       = each.value.network_tier
  subnetwork         = each.value.subnetwork
  network            = each.value.network
  prefix_length      = each.value.prefix_length
  #ip_version         = each.value.ip_version
  #ipv6_endpoint_type = each.value.ipv6_endpoint_type
  region             = each.value.region
}

# resource "google_compute_disk" "this" {
#   for_each = var.instance.attached_disks != null ? { for attached_disk in var.instance.attached_disks : attached_disk["device_name"] => attached_disk } : {}
#   name     = format("%s-%s", var.instance.name, each.key)
#   zone     = var.instance.zone
#   size     = each.value["size_gb"]
# }
resource "google_compute_disk" "this" {
  for_each = var.instance.data_disks != null ? { for data_disk in var.instance.data_disks : data_disk["device_name"] => data_disk } : {}
  name     = format("%s-%s", var.instance.name, each.key)
  zone     = var.instance.zone
  size     = each.value["size_gb"]
}

resource "google_compute_instance" "default" {
  provider = google

  machine_type = var.instance.machine_type
  name         = var.instance.name

  allow_stopping_for_update = var.instance.allow_stopping_for_update
  can_ip_forward            = var.instance.can_ip_forward
  deletion_protection       = var.instance.deletion_protection
  description               = var.instance.description
  desired_status            = var.instance.desired_status
  enable_display            = var.instance.enable_display
  hostname                  = var.instance.hostname
  labels                    = var.instance.labels
  metadata                  = var.instance.metadata
  metadata_startup_script   = var.instance.metadata_startup_script
  min_cpu_platform          = var.instance.min_cpu_platform
  resource_policies         = var.instance.resource_policies
  tags                      = var.instance.tags
  zone                      = var.instance.zone

  dynamic "advanced_machine_features" {
    for_each = var.instance.advanced_machine_features != null ? [var.instance.advanced_machine_features] : []

    content {
      enable_nested_virtualization = advanced_machine_features.value["enable_nested_virtualization"]
      threads_per_core             = advanced_machine_features.value["threads_per_core"]
      visible_core_count           = advanced_machine_features.value["visible_core_count"]
    }
  }

  # dynamic "attached_disk" {
  #   #for_each = var.instance.attached_disks != null ? var.instance.attached_disks : []
  #   for_each = var.instance.attached_disks != null ? toset([for attached_disk in var.instance.attached_disks : attached_disk["device_name"]]) : []
  #   content {
  #     device_name             = attached_disk.value["device_name"]
  #     disk_encryption_key_raw = attached_disk.value["disk_encryption_key_raw"]
  #     kms_key_self_link       = attached_disk.value["kms_key_self_link"]
  #     mode                    = attached_disk.value["mode"]
  #     source                  = google_compute_disk.this[attached_disk.key].self_link
  #   }
  # }

  dynamic "attached_disk" {
    for_each = var.instance.data_disks != null ?  toset([for data_disk in var.instance.data_disks : data_disk["device_name"]]) : []
    content {
      source      = google_compute_disk.this[attached_disk.key].self_link
      device_name = attached_disk.key
    }
  }

  dynamic "boot_disk" {
    for_each = var.instance.boot_disk != null ? [var.instance.boot_disk] : []

    content {
      auto_delete             = boot_disk.value["auto_delete"]
      device_name             = boot_disk.value["device_name"]
      disk_encryption_key_raw = boot_disk.value["disk_encryption_key_raw"]
      kms_key_self_link       = boot_disk.value["kms_key_self_link"]
      mode                    = boot_disk.value["mode"]
      source                  = boot_disk.value["source"]

      dynamic "initialize_params" {
        for_each = boot_disk.value["initialize_params"] != null ? [boot_disk.value["initialize_params"]] : []

        content {
          #enable_confidential_compute = initialize_params.value["enable_confidential_compute"]
          image                       = initialize_params.value["image"]
          labels                      = initialize_params.value["labels"]
          #resource_manager_tags       = initialize_params.value["resource_manager_tags"]
          #provisioned_iops            = initialize_params.value["provisioned_iops"]
          #provisioned_throughput      = initialize_params.value["provisioned_throughput"]
          size                        = initialize_params.value["size"]
          type                        = initialize_params.value["type"]
        }
      }
    }
  }

  dynamic "confidential_instance_config" {
    for_each = var.instance.confidential_instance_config != null ? [var.instance.confidential_instance_config] : []

    content {
      enable_confidential_compute = confidential_instance_config.value["enable_confidential_compute"]
      #confidential_instance_type  = confidential_instance_config.value["confidential_instance_type"]
    }
  }

  dynamic "guest_accelerator" {
    for_each = var.instance.guest_accelerator != null ? var.instance.guest_accelerator : []

    content {
      count = guest_accelerator.value["count"]
      type  = guest_accelerator.value["type"]
    }
  }

  dynamic "network_interface" {
    for_each = var.instance.network_interface != null ? var.instance.network_interface : []

    content {
      network     = network_interface.value["network"]
      network_ip  = network_interface.value["network_ip"]
      nic_type    = network_interface.value["nic_type"]
      queue_count = network_interface.value["queue_count"]
      subnetwork  = network_interface.value["subnetwork"]
      stack_type  = network_interface.value["stack_type"]

      dynamic "alias_ip_range" {
        for_each = network_interface.value["alias_ip_range"] != null ? network_interface.value["alias_ip_range"] : []

        content {
          ip_cidr_range         = alias_ip_range.value["ip_cidr_range"]
          subnetwork_range_name = alias_ip_range.value["subnetwork_range_name"]
        }
      }

      dynamic "access_config" {
        for_each = network_interface.value["access_config"] != null ? network_interface.value["access_config"] : []

        content {
          nat_ip                 = access_config.value["nat_ip"] != null ? coalesce(try(google_compute_address.default[access_config.value["nat_ip"]].address, null), access_config.value["nat_ip"]) : null
          public_ptr_domain_name = access_config.value["public_ptr_domain_name"]
          network_tier           = access_config.value["network_tier"]
        }
      }
    }
  }

  # dynamic "params" {
  #   for_each = var.instance.params != null ? [var.instance.params] : []

  #   content {
  #     resource_manager_tags = params.value["resource_manager_tags"]
  #   }
  # }

  dynamic "reservation_affinity" {
    for_each = var.instance.reservation_affinity != null ? [var.instance.reservation_affinity] : []

    content {
      type = reservation_affinity.value["type"]

      dynamic "specific_reservation" {
        for_each = reservation_affinity.value["specific_reservation"] != null ? [reservation_affinity.value["specific_reservation"]] : []

        content {
          key    = specific_reservation.value["key"]
          values = specific_reservation.value["values"]
        }
      }
    }
  }

  dynamic "scheduling" {
    for_each = var.instance.scheduling != null ? [var.instance.scheduling] : []

    content {
      preemptible                 = scheduling.value["preemptible"]
      on_host_maintenance         = scheduling.value["on_host_maintenance"]
      automatic_restart           = scheduling.value["automatic_restart"]
      min_node_cpus               = scheduling.value["min_node_cpus"]
      provisioning_model          = scheduling.value["provisioning_model"]
      instance_termination_action = scheduling.value["instance_termination_action"]

      # dynamic "local_ssd_recovery_timeout" {
      #   for_each = scheduling.value["local_ssd_recovery_timeout"] != null ? [scheduling.value["local_ssd_recovery_timeout"]] : []

      #   content {
      #     nanos   = local_ssd_recovery_timeout.value["nanos"]
      #     seconds = local_ssd_recovery_timeout.value["seconds"]
      #   }
      # }

      # dynamic "max_run_duration" {
      #   for_each = scheduling.value["max_run_duration"] != null ? [scheduling.value["max_run_duration"]] : []

      #   content {
      #     nanos   = max_run_duration.value["nanos"]
      #     seconds = max_run_duration.value["seconds"]
      #   }
      # }

      dynamic "node_affinities" {
        for_each = scheduling.value["node_affinities"] != null ? scheduling.value["node_affinities"] : []

        content {
          key      = node_affinities.value["key"]
          operator = node_affinities.value["operator"]
          values   = node_affinities.value["values"]
        }
      }
    }
  }

  dynamic "scratch_disk" {
    for_each = var.instance.scratch_disk != null ? var.instance.scratch_disk : []

    content {
      interface = scratch_disk.value["interface"]
    }
  }

  dynamic "service_account" {
    for_each = var.instance.service_account != null ? [var.instance.service_account] : []

    content {
      email  = service_account.value["email"]
      scopes = service_account.value["scopes"]
    }
  }

  dynamic "shielded_instance_config" {
    for_each = var.instance.shielded_instance_config != null ? [var.instance.shielded_instance_config] : []

    content {
      enable_integrity_monitoring = shielded_instance_config.value["enable_integrity_monitoring"]
      enable_secure_boot          = shielded_instance_config.value["enable_secure_boot"]
      enable_vtpm                 = shielded_instance_config.value["enable_vtpm"]
    }
  }
}
