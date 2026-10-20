{ lib }:

# matt's SSH public keys, sourced from https://mattrobenolt.com/id_ed25519.pub
# (mirrors github.com/mattrobenolt.keys). The URL is the canonical record;
# the sha256 pins content, so rotating the key means updating the hash here
# (eval fails loudly on mismatch, it never silently swaps keys).
let
  raw = lib.strings.trim (
    builtins.readFile (
      builtins.fetchurl {
        url = "https://mattrobenolt.com/id_ed25519.pub";
        sha256 = "sha256-seWKBEqvkd+YNtWUJjLkuR69SNDQ+3H1JayfbzTrB2M=";
      }
    )
  );
  # The launchpad box's own keypair (GitHub auth + signing key; the private
  # half is secrets/launchpad-id-ed25519.age, see hosts/nixos/launchpad/).
  launchpad = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII13XL4pqymylPqF41vFZP74+91X5O017M/Tu7Jb6MR3 matt@launchpad";
  # "ssh-ed25519 AAAA... comment" -> bare "algo base64" (some consumers,
  # e.g. git user.signingKey, don't want the comment).
  bare = key: builtins.concatStringsSep " " (lib.lists.take 2 (lib.strings.splitString " " key));
in
{
  mattMain = bare raw;
  mattMainWithComment = raw;
  launchpadMain = bare launchpad;
  launchpadMainWithComment = launchpad;
}
