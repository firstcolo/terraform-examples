terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.47.0"
    }
  }
}

provider "openstack" {
  use_octavia = true
}

/*
 Data Sources
*/

data "openstack_networking_network_v2" "external-network" {
  name = "Extern"
}

data "openstack_images_image_v2" "image" {
  name = "ubuntu-2004-latest"
}


/*
 Network 
*/

resource "openstack_compute_secgroup_v2" "demosecgroup-ssh" {
  name        = "demosecgroup-ssh"
  description = "Allow inbound SSH"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "demosecgroup-web" {
  name        = "demosecgroup-web"
  description = "Allow inbound Web Port 80"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "demonet" {
  name           = "demonet"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "demosubnet" {
  name            = "demosubnet"
  network_id      = openstack_networking_network_v2.demonet.id
  cidr            = "10.100.10.0/24"
  dns_nameservers = ["212.224.71.17", "79.133.62.62"]
  ip_version      = 4
}

resource "openstack_networking_router_v2" "demorouter" {
  name                = "demorouter"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external-network.id
}

resource "openstack_networking_router_interface_v2" "demorouter_int" {
  router_id = openstack_networking_router_v2.demorouter.id
  subnet_id = openstack_networking_subnet_v2.demosubnet.id
}


/*
Instances
*/

resource "openstack_compute_keypair_v2" "demokey" {
  name       = "demokey"
  public_key = var.demokey
}

resource "openstack_compute_instance_v2" "demoinstances" {
  count       = 3
  name        = "Demo Instance ${count.index + 1}"
  flavor_name = "g2.small"
  key_pair    = openstack_compute_keypair_v2.demokey.name
  user_data   = file("${path.module}/cloud.cfg")

  block_device {
    uuid                  = data.openstack_images_image_v2.image.id
    source_type           = "image"
    volume_size           = 25
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  security_groups = [
    "default",
    openstack_compute_secgroup_v2.demosecgroup-web.name,
  ]

  network {
    uuid = openstack_networking_network_v2.demonet.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "openstack_compute_instance_v2" "instance_jumphost" {
  name        = "Jumphost"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = "g2.small"
  key_pair    = openstack_compute_keypair_v2.demokey.name

  security_groups = [
    "default",
    openstack_compute_secgroup_v2.demosecgroup-ssh.name,
  ]

  network {
    uuid = openstack_networking_network_v2.demonet.id
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

/*
 Floating IP -> Jumphost Instance
*/

resource "openstack_networking_floatingip_v2" "demofip_jumphost" {
  pool = "Extern"
}

resource "openstack_compute_floatingip_associate_v2" "demofipas_jumphost" {
  floating_ip = openstack_networking_floatingip_v2.demofip_jumphost.address
  instance_id = openstack_compute_instance_v2.instance_jumphost.id
}


/*
 Loadbalancer
*/

resource "openstack_lb_loadbalancer_v2" "demolb" {
  vip_subnet_id = openstack_networking_subnet_v2.demosubnet.id
  name          = "Web loadbalancer"
}

resource "openstack_lb_listener_v2" "demolb_web_listener" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.demolb.id
  allowed_cidrs   = ["0.0.0.0/0"]
  insert_headers = {
    X-Forwarded-For  = "true"
    X-Forwarded-Port = "true"
  }
}

resource "openstack_lb_pool_v2" "demolb_web_pool" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.demolb_web_listener.id
}

resource "openstack_lb_member_v2" "demolb_web_pool_members" {
  count = length(openstack_compute_instance_v2.demoinstances)
  address = element(
    openstack_compute_instance_v2.demoinstances.*.access_ip_v4,
    count.index,
  )
  protocol_port = 80
  pool_id       = openstack_lb_pool_v2.demolb_web_pool.id
  name = element(
    openstack_compute_instance_v2.demoinstances.*.name,
    count.index,
  )
  subnet_id = openstack_networking_subnet_v2.demosubnet.id
}

resource "openstack_lb_monitor_v2" "demolb_monitor" {
  pool_id        = openstack_lb_pool_v2.demolb_web_pool.id
  type           = "HTTP"
  delay          = 10
  timeout        = 5
  max_retries    = 2
  url_path       = "/"
  expected_codes = 200
}

/*
 Floating IP -> Demo loadbalancer
*/

resource "openstack_networking_floatingip_v2" "demofip_loadbalancer" {
  pool = "Extern"
}

resource "openstack_networking_floatingip_associate_v2" "demofipas_loadbalancer" {
  floating_ip = openstack_networking_floatingip_v2.demofip_loadbalancer.address
  port_id     = openstack_lb_loadbalancer_v2.demolb.vip_port_id
}

output "loadbalancer_http" {
  value = "http://${openstack_networking_floatingip_v2.demofip_loadbalancer.address}"
}
