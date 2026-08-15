_: {
  # Shared ssh config (github.com host) lives in hosts/nixos/home.nix.
  # Desktop-only: use the 1Password GUI agent when a Wayland session exists.
  programs.ssh.settings = {
    "Match exec \"test -n \\\"$WAYLAND_DISPLAY\\\"\"" = {
      IdentityAgent = "~/.1password/agent.sock";
    };
  };
}
