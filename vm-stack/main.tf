module "vms" {
  source   = "./modules/vm"
  for_each = var.vms

  name            = each.key
  mac_address     = each.value.mac
  image_name      = coalesce(each.value.image_name, var.default_image_name)
  flavor_id       = coalesce(each.value.flavor_id, var.default_flavor_id)
  network_id      = coalesce(each.value.network_id, var.default_network_id)
  key_pair        = coalesce(each.value.key_pair, var.default_key_pair)
  security_groups = coalesce(each.value.security_groups, var.default_security_groups)
  disks           = coalesce(each.value.disks, var.default_disks)
  user_data       = coalesce(each.value.user_data, var.default_user_data)
}