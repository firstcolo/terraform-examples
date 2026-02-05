# Terraform / OpenTofu – VM Provisioning with Custom Definitions

This repository provides a **clean, extensible OpenTofu (Terraform fork) example** for creating **multiple OpenStack VMs** using a single, declarative configuration.

You can define per‑VM overrides (image, flavor, network, disks, cloud‑init, etc.) while keeping **sane global defaults** for everything else.

The setup is designed to be:

- ✅ Easy to extend
- ✅ Safe for large VM maps
- ✅ Explicit but not repetitive
- ✅ Compatible with OpenTofu (`tofu`)

---

## 📦 What This Project Does

- Creates **multiple virtual machines** from a single `vms` map
- Supports **per‑VM overrides** for:
  - MAC Addresses
  - Image
  - Flavor
  - Network
  - Security groups
  - SSH keypair
  - Disks (additional volumes)
  - Cloud‑init configuration
- Uses **defaults** automatically when values are omitted
- Boots instances from **volume** (recommended for OpenStack)

---

## 🧱 Project Structure

```
.
├── main.tf                 # Root module
├── variables.tf            # Root variables (defaults + VM map)
├── terraform.tfvars        # Your environment-specific values
├── modules/
│   └── vm/
│       ├── main.tf         # VM resources (port, volumes, instance)
│       ├── variables.tf    # VM module variables
└── README.md
```

---

## 🔐 Prerequisites

- OpenTofu installed (`>= 1.x`)
- OpenStack credentials configured
- Access to an OpenStack project

### API Access

Follow the official guide to configure API access:

👉 https://docs.cloud-fc.de/firststeps/api-access/

You should end up with:

- `OS_AUTH_URL`
- `OS_PROJECT_ID`
- `OS_USERNAME`
- `OS_PASSWORD`
- `OS_REGION_NAME`

Exported as environment variables or sourced from an RC file.

---

## ⚙️ Step 1: Configure Defaults (`terraform.tfvars`)

Define your **global defaults** once. These are used automatically unless a VM overrides them.

Example:

```hcl
default_image_name      = "Ubuntu 24.04"
default_flavor_id       = "4d17d64f-c1c7-42e1-93f9-ff594ae90384"
default_network_id      = "0363eebc-94fa-4009-be7d-c744fb5c9b2f"
default_key_pair        = "SSH Key MR"
default_security_groups = ["b5a1469f-8a19-442f-9ab8-b0da275fd10e"]

default_disks = [
  { name = "data1", size = 10 },
  { name = "data2", size = 20 }
]
```

---

## 🖥 Step 2: Define Your Architecture (`vms` map)

All VMs are defined in **one map**. Each entry represents one VM.

### Minimal VM (uses all defaults)

```hcl
vms = {
  vm005 = {}
}
```

---

### VM with Overrides

```hcl
vms = {
  vm001 = {
    mac         = "fa:16:3e:aa:bb:01"
    image_name  = "Ubuntu 22.04"
    flavor_id   = "m4.small"
    network_id  = "0363eebc-94fa-4009-be7d-c744fb5c9b2f"

    disks = [
      { name = "data1", size = 50 },
      { name = "data2", size = 60 }
    ]
  }
}
```

---


## 💾 Disks & Volumes

- All VMs boot from a **root volume** created from the image
- Additional disks are created as **Cinder volumes**
- Disks are attached automatically

---

## 🚀 Usage

### Initialize

```bash
tofu init
```

### Plan

```bash
tofu plan
```

### Apply

```bash
tofu apply
```

---


## 🧹 Cleanup

```bash
tofu destroy
```
