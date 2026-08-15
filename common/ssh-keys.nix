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
  # "ssh-ed25519 AAAA... comment" -> bare "algo base64" (some consumers,
  # e.g. git user.signingKey, don't want the comment).
  parts = lib.strings.splitString " " raw;
in
{
  mattMain = builtins.concatStringsSep " " (lib.lists.take 2 parts);
  mattMainWithComment = raw;
}
