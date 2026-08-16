# agenix rules: each secret's recipient public keys. Any recipient's private
# key can decrypt. `agenix -r` (rekey) re-reads this file.
#
# matt     = matt's daily key (canonical: https://mattrobenolt.com/id_ed25519.pub,
#            mirrored in common/ssh-keys.nix). Used for editing on the Mac.
# launchpad = the box's SSH host key. PINNED — the private half lives in the
#            launchpad 1Password vault; rebirths restore it, so this recipient
#            is stable forever. Do not rotate casually: everything rekeys.
let
  matt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTuvuCDtmFBcTEkfOyx1NlUJZPcCJ76cChOt8ACBGKG";
  launchpad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKfBeK7JzwDd6pFd07dXnzNXIqyBaiNg4t9Fu4wf5x1b";
in
{
  "syncthing-key.pem.age".publicKeys = [
    matt
    launchpad
  ];
  "syncthing-cert.pem.age".publicKeys = [
    matt
    launchpad
  ];
}
