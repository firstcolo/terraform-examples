resource "openstack_networking_port_v2" "port" {
  name               = "${var.name}-port"
  network_id         = var.network_id     
  security_group_ids  = var.security_groups

  mac_address = var.mac_address != null ? var.mac_address : null
}


data "openstack_images_image_v2" "image" {
  name = var.image_name
  most_recent = true
}

resource "openstack_blockstorage_volume_v3" "volumes" {
  for_each = { for d in var.disks : d.name => d }

  name = "${var.name}-${each.key}"
  size = each.value.size
}

resource "openstack_compute_instance_v2" "vm" {
  name      = var.name
  flavor_id    = var.flavor_id
  key_pair   = var.key_pair
  user_data = var.user_data

  network {
    port = openstack_networking_port_v2.port.id
  }

  block_device {
    uuid                  = data.openstack_images_image_v2.image.id
    source_type           = "image"
    destination_type      = "volume"
    boot_index            = 0
    volume_size           = 40
    delete_on_termination = false
  }

  dynamic "block_device" {
    for_each = openstack_blockstorage_volume_v3.volumes
    content {
      uuid                  = block_device.value.id
      source_type           = "volume"
      destination_type      = "volume"
      boot_index            = -1
      delete_on_termination = false
    }
  }
}


