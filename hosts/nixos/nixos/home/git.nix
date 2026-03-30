{ pkgs, ... }:

{
  programs.git.settings.gpg.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
}
