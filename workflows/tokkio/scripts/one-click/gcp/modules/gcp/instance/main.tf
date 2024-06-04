# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

resource "google_compute_address" "this" {
  count  = var.static_public_ip ? 1 : 0
  name   = var.name
  region = var.region
}

resource "google_compute_disk" "this" {
  for_each = { for data_disk in var.data_disks : data_disk["device_name"] => data_disk }
  name     = format("%s-%s", var.name, each.key)
  zone     = var.zone
  size     = each.value["size_gb"]
}

resource "google_compute_instance" "this" {
  name                      = var.name
  zone                      = var.zone
  machine_type              = var.machine_type
  allow_stopping_for_update = true
  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }
  boot_disk {
    device_name = var.boot_disk.device_name
    auto_delete = var.boot_disk.auto_delete
    initialize_params {
      size  = var.boot_disk.size_gb
      image = var.boot_disk.source_image
      type  = var.boot_disk.type
    }
  }
  dynamic "attached_disk" {
    for_each = toset([for data_disk in var.data_disks : data_disk["device_name"]])
    content {
      source      = google_compute_disk.this[attached_disk.key].self_link
      device_name = attached_disk.key
    }
  }
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    dynamic "access_config" {
      for_each = var.network_interface.access_configs
      content {
        nat_ip       = one(google_compute_address.this.*.address)
        network_tier = access_config.value["network_tier"]
      }
    }
  }
  dynamic "advanced_machine_features" {
    for_each = var.advanced_machine_features
    content {
      enable_nested_virtualization = advanced_machine_features.value["enable_nested_virtualization"]
      threads_per_core             = advanced_machine_features.value["threads_per_core"]
      visible_core_count           = advanced_machine_features.value["visible_core_count"]
    }
  }
  dynamic "guest_accelerator" {
    for_each = var.guest_accelerators
    content {
      count = guest_accelerator.value["count"]
      type  = guest_accelerator.value["type"]
    }
  }
  dynamic "scheduling" {
    for_each = var.schedulings
    content {
      on_host_maintenance = scheduling.value["on_host_maintenance"]
    }
  }
  reservation_affinity {
    type = "ANY_RESERVATION"
  }
  metadata = merge(var.additional_metadata, {
    ssh-keys = join("\n", [
      format("%s:%s %s", var.ssh_user, join(" ", slice(split(" ", var.ssh_public_key), 0, 2)), var.ssh_user)
    ])
  })
  metadata_startup_script = var.metadata_startup_script
  tags                    = var.tags
}