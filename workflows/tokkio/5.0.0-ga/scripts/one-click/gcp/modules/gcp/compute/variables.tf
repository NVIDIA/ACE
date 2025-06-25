variable "compute_addresses" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address"
  type = map(object({
    name               = optional(string)
    address            = optional(string)
    address_type       = optional(string)
    description        = optional(string)
    purpose            = optional(string)
    network_tier       = optional(string)
    subnetwork         = optional(string)
    network            = optional(string)
    prefix_length      = optional(string)
    ip_version         = optional(string)
    ipv6_endpoint_type = optional(string)
    region             = optional(string)
  }))
}

variable "instance" {
  description = "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance"
  type = object({
    boot_disk = object({
      auto_delete             = optional(bool)
      device_name             = optional(string)
      mode                    = optional(string)
      disk_encryption_key_raw = optional(string)
      kms_key_self_link       = optional(string)
      initialize_params = optional(object({
        size                        = optional(number)
        type                        = optional(string)
        image                       = optional(string)
        labels                      = optional(map(string))
        resource_manager_tags       = optional(map(string))
        provisioned_iops            = optional(number)
        provisioned_throughput      = optional(number)
        enable_confidential_compute = optional(bool)
      }))
      source = optional(string)
    })
    data_disks = optional(list(object({
      device_name = string
      size_gb     = number
      type        = string
      auto_delete = bool
    })))
    machine_type = string
    name         = string
    zone         = optional(string)
    network_interface = list(object({
      network    = optional(string)
      subnetwork = optional(string)
      network_ip = optional(string)
      access_config = optional(list(object({
        nat_ip                 = optional(string)
        public_ptr_domain_name = optional(string)
        network_tier           = optional(string)
      })))
      alias_ip_range = optional(list(object({
        ip_cidr_range         = string
        subnetwork_range_name = optional(string)
      })))
      nic_type   = optional(string)
      stack_type = optional(string)
      ipv6_access_config = optional(list(object({
        external_ipv6               = optional(string)
        external_ipv6_prefix_length = optional(number)
        name                        = optional(string)
        network_tier                = optional(string)
        public_ptr_domain_name      = optional(string)
      })))
      queue_count = optional(number)
    }))
    allow_stopping_for_update = optional(bool)
    attached_disks = optional(list(object({
      source                  = optional(number)
      device_name             = optional(string)
      mode                    = optional(string)
      disk_encryption_key_raw = optional(string)
      kms_key_self_link       = optional(string)
      size_gb                 = optional(number)
    })))
    can_ip_forward      = optional(bool)
    description         = optional(string)
    desired_status      = optional(string)
    deletion_protection = optional(bool)
    hostname            = optional(string)
    guest_accelerator = optional(list(object({
      type  = string
      count = number
    })))
    labels                  = optional(map(string))
    metadata                = optional(map(string))
    metadata_startup_script = optional(string)
    min_cpu_platform        = optional(string)
    params = optional(object({
      resource_manager_tags = optional(map(string))
    }))
    scheduling = optional(object({
      preemptible         = optional(bool)
      on_host_maintenance = optional(string)
      automatic_restart   = optional(bool)
      node_affinities = optional(list(object({
        key      = string
        operator = string
        values   = list(string)
      })))
      min_node_cpus               = optional(number)
      provisioning_model          = optional(string)
      instance_termination_action = optional(string)
      max_run_duration = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
      local_ssd_recovery_timeout = optional(object({
        seconds = number
        nanos   = optional(number)
      }))
    }))
    scratch_disk = optional(list(object({
      interface = string
    })))
    service_account = optional(object({
      email  = string
      scopes = list(string)
    }))
    tags = optional(list(string))
    shielded_instance_config = optional(object({
      enable_secure_boot          = optional(bool)
      enable_vtpm                 = optional(bool)
      enable_integrity_monitoring = optional(bool)
    }))
    enable_display    = optional(bool)
    resource_policies = optional(list(string))
    reservation_affinity = optional(object({
      type = string
      specific_reservation = optional(object({
        key    = string
        values = list(string)
      }))
    }))
    confidential_instance_config = optional(object({
      enable_confidential_compute = optional(bool)
      confidential_instance_type  = optional(string)
    }))
    advanced_machine_features = optional(object({
      enable_nested_virtualization = optional(bool)
      threads_per_core             = optional(number)
      visible_core_count           = optional(number)
    }))
  })
}