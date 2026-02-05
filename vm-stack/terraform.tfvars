default_image_name      = "Ubuntu 24.04"
default_flavor_id       = "4d17d64f-c1c7-42e1-93f9-ff594ae90384"   # m4.small
default_network_id      = "0363eebc-94fa-4009-be7d-c744fb5c9b2f"   # net-mr
default_security_groups = ["b5a1469f-8a19-442f-9ab8-b0da275fd10e"] # default security group
default_key_pair        = "SSH Key MR"                             # default keypair as in "openstack keypair list"
default_disks = [                                                  # default disks attached to the VM
  { name = "data1", size = 10 },
  { name = "data2", size = 20 }
]

# default cloud init
default_user_data = <<-EOF
  #cloud-config
  package_update: true
  package_upgrade: true
  packages:
    - htop
    - vim
  runcmd:
    - echo "Default cloud-init executed" > /root/cloud-init.log
EOF

# architecture definition
vms = {
  vm001 = {
    mac             = "fa:16:3e:aa:bb:01"
    image_name      = "Ubuntu 22.04"
    flavor_id       = "4d17d64f-c1c7-42e1-93f9-ff594ae90384"
    network_id      = "0363eebc-94fa-4009-be7d-c744fb5c9b2f"
    key_pair        = "SSH Key MR"
    security_groups = ["b5a1469f-8a19-442f-9ab8-b0da275fd10e"] # default security group
    disks = [
      { name = "data1", size = 50 },
      { name = "data2", size = 60 }
    ]
  }

  vm002 = {
    security_groups = ["b5a1469f-8a19-442f-9ab8-b0da275fd10e", "0010166e-d2e9-4994-98e8-2e2e861b09ed"] # default and allow ssh public security groups
    # everything else falls back to default
    user_data = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - docker.io
        - nginx
      runcmd:
        - systemctl start docker
        - systemctl enable docker
        - echo "custom init is working" > /root/vm001.log
    EOF
  }

  vm003 = {
    image_name = "Debian 13"
  }
}
