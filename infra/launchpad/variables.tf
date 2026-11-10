variable "name" {
  description = "Name tag for the instance and prefix for resources."
  type        = string
  default     = "launchpad"
}

variable "region" {
  description = "AWS region. us-west-2 for latency to LA."
  type        = string
  default     = "us-west-2"
}

variable "profile" {
  description = "AWS CLI/SSO profile to use (the playground account). playground-ops (Ops role) is the fallback if PowerUser lacks a permission."
  type        = string
  default     = "playground"
}

variable "instance_type" {
  description = "Instance type. c9g.2xlarge: 8 vCPU / 16 GiB. Same memory as m9g.xlarge, twice the cores."
  type        = string
  default     = "c9g.2xlarge"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB (encrypted gp3)."
  type        = number
  default     = 50
}

variable "root_volume_iops" {
  description = "Provisioned IOPS for the root gp3 volume."
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Provisioned throughput for the root gp3 volume in MiB/s."
  type        = number
  default     = 125
}

variable "data_volume_iops" {
  description = "Provisioned IOPS for the data gp3 volume."
  type        = number
  default     = 6000
}

variable "data_volume_throughput" {
  description = "Provisioned throughput for the data gp3 volume in MiB/s."
  type        = number
  default     = 250
}

variable "data_volume_size" {
  description = "Data EBS volume in GiB (btrfs: /nix, /Users/matt, /tmp). EBS cannot shrink this volume."
  type        = number
  default     = 200
}

variable "arch" {
  description = "CPU architecture. Used to pick the bootstrap AMI. The flake pins the NixOS system separately."
  type        = string
  default     = "aarch64"

  validation {
    condition     = contains(["aarch64", "x86_64"], var.arch)
    error_message = "arch must be aarch64 or x86_64."
  }
}

variable "nixos_release" {
  description = "NixOS release series for the AMI filter (AMIs older than 90 days are garbage collected)."
  type        = string
  default     = "26.05"
}

variable "ssh_public_key" {
  description = "SSH public key installed as the EC2 keypair; the NixOS AMI injects it for root at boot. Matt's daily key — the same one in hosts/nixos/launchpad/default.nix. There is deliberately no separate bootstrap key. Auto-loaded from terraform.tfvars."
  type        = string
}

