locals {
  # The AMI feed uses arm64/x86_64 naming; our var uses nix-style naming.
  ami_arch = var.arch == "aarch64" ? "arm64" : "x86_64"
}

# Latest official NixOS AMI, published weekly to all regions by the NixOS
# project. AMIs older than 90 days are garbage collected, so always query
# rather than pin an ID. Feed: https://nixos.github.io/amis/images.json
data "aws_ami" "nixos" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/${var.nixos_release}*"]
  }

  filter {
    name   = "architecture"
    values = [local.ami_arch]
  }
}

resource "aws_key_pair" "bootstrap" {
  key_name   = "${var.name}-bootstrap"
  public_key = var.ssh_public_key
}

resource "aws_security_group" "main" {
  name        = var.name
  description = "launchpad: SSH during bootstrap, egress-only otherwise"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH (temporary - the tailscale iteration removes this)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # syncthing: designed for untrusted networks (mutual TLS, the device ID is
  # the cert fingerprint — unknown peers get nothing). Exposed on purpose.
  ingress {
    description = "syncthing TCP"
    from_port   = 22000
    to_port     = 22000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "syncthing QUIC"
    from_port   = 22000
    to_port     = 22000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # WireGuard/tailscale: direct connections instead of DERP relays.
  # Mutual-auth protocol; fine to expose.
  ingress {
    description = "tailscale WireGuard"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # mosh: roaming shell over the public EIP (the break-glass path when not
  # on the tailnet). SSH authenticates the bootstrap and negotiates the
  # session key; only a holder of that key can do anything with the UDP
  # port, so the range is safe to expose like syncthing/tailscale above.
  ingress {
    description = "mosh"
    from_port   = 60000
    to_port     = 61000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.name
  }
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.nixos.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.bootstrap.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]

  # No instance profile on purpose. Agents use matt's short-lived SSO creds;
  # the box itself holds no standing AWS power.

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    # The data source tracks the weekly NixOS AMI publishes. Without this,
    # every new AMI would force instance replacement on the next apply. The
    # AMI only matters at creation; nixos-rebuild owns the box afterwards.
    # To rebirth onto a newer AMI: tofu apply -replace=aws_instance.main
    ignore_changes = [ami, tags]
  }

  tags = {
    Name = var.name
  }
}

# Stable public IP across stop/retype/start resize cycles. Cheap while
# attached; keeps known_hosts and future herdr/SSH config from churning.
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = var.name
  }
}
