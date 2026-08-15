provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      project    = "launchpad"
      managed-by = "opentofu"
      repo       = "nix-darwin"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
