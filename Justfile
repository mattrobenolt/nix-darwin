[private]
default:
    @just --list

# launchpad EC2 box. EIP is stable across stop/retype; swap for the
# tailscale hostname once the box joins the tailnet.
launchpad_host := "52.25.100.5"
aws_profile := "playground"
aws_region := "us-west-2"

[doc("Build the current host config without activating it")]
[group("nix")]
[macos]
check:
    darwin-rebuild build --flake .

[doc("Build the current host config without activating it")]
[group("nix")]
[linux]
check:
    nixos-rebuild build --flake .

[doc("Rebuild and switch to the current flake config for this host")]
[group("nix")]
[macos]
apply:
    sudo darwin-rebuild switch --flake .

[doc("Rebuild and switch to the current flake config for this host")]
[group("nix")]
[linux]
apply:
    sudo nixos-rebuild switch --flake .

[doc("Rebuild and switch the launchpad box (evals locally, builds on the box)")]
[group("remote")]
remote-apply:
    nixos-rebuild switch --flake .#launchpad --target-host root@{{ launchpad_host }} --build-host root@{{ launchpad_host }}

[doc("Start the launchpad instance and wait for SSH")]
[group("remote")]
remote-up:
    #!/usr/bin/env bash
    set -euo pipefail
    id=$(tofu -chdir=infra/launchpad output -raw instance_id)
    aws=(aws --profile {{ aws_profile }} --region {{ aws_region }})
    state=$("${aws[@]}" ec2 describe-instances --instance-ids "$id" \
      --query 'Reservations[0].Instances[0].State.Name' --output text)
    if [ "$state" != "running" ]; then
      "${aws[@]}" ec2 start-instances --instance-ids "$id" --output text > /dev/null
      "${aws[@]}" ec2 wait instance-running --instance-ids "$id"
      echo "instance running; waiting for sshd..."
      until ssh -o BatchMode=yes -o ConnectTimeout=5 matt@{{ launchpad_host }} true 2>/dev/null; do sleep 3; done
    fi
    echo "up: ssh matt@{{ launchpad_host }}"

[doc("Stop the launchpad instance (EBS + config persist; EIP keeps the IP)")]
[group("remote")]
remote-down:
    #!/usr/bin/env bash
    set -euo pipefail
    id=$(tofu -chdir=infra/launchpad output -raw instance_id)
    aws=(aws --profile {{ aws_profile }} --region {{ aws_region }})
    state=$("${aws[@]}" ec2 describe-instances --instance-ids "$id" \
      --query 'Reservations[0].Instances[0].State.Name' --output text)
    if [ "$state" = "running" ]; then
      "${aws[@]}" ec2 stop-instances --instance-ids "$id" --output text --query 'StoppingInstances[0].CurrentState.Name'
    else
      echo "already $state"
    fi

[doc("Format all nix files")]
[group("nix")]
fmt:
    nix fmt -- --tree-root .

[doc("Check for linting issues")]
[group("nix")]
lint:
    statix check --ignore .direnv --ignore '**/hardware-configuration.nix' .
    fd --extension nix --exclude hardware-configuration.nix --exclude .direnv --exec-batch deadnix

[doc("Fix linting issues automatically")]
[group("nix")]
fix:
    statix fix --ignore .direnv --ignore '**/hardware-configuration.nix' .
    fd --extension nix --exclude hardware-configuration.nix --exclude .direnv --exec-batch deadnix --edit

[doc("Update flake inputs. Groups: core ghostty herdr hyprland neovim (omit for interactive picker)")]
[group("scripts")]
update *groups:
    @nu scripts/update.nu {{ groups }}
