# Shared system settings for every NixOS host. The macOS host does not import
# this file.
{
  # Remove these CAs from /etc/ssl/certs/ca-certificates.crt. Each name must
  # match the certificate's label in the NSS trust store, not its subject CN.
  #
  # Why: eMudhra's eight intermediate CA private keys were compromised
  # (reported 2026-10-17). The affected intermediates chain to these roots.
  # Blacklisting the roots blocks those chains on clients that do not process
  # revocation data. https://emudhra.we-have-a-problem.com/
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
}
