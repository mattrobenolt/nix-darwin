{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

let
  nixSettings = import ../../../common/nix-settings.nix;

in

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  nixpkgs.config.allowUnfree = true;
  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "26.05";

  networking = {
    hostName = "orbstack";
    dhcpcd = {
      enable = false;
      extraConfig = ''
        noarp
        noipv6
      '';
    };
    useDHCP = false;
    useHostResolvConf = false;
    enableIPv6 = false;
    resolvconf.enable = false;
  };

  environment = {
    systemPackages = with pkgs; [
      curl
      dig
      file
      ghostty.terminfo
      hivemind
      neovim
      nixfmt
      psmisc
      strace
      wget
      zsh
    ];

    shellInit = ''
      . /opt/orbstack-guest/etc/profile-early

      # add your customizations here

      . /opt/orbstack-guest/etc/profile-late
    '';

    etc."resolv.conf".source = "/opt/orbstack-guest/etc/resolv.conf";
  };

  users = {
    mutableUsers = false;
    groups.orbstack.gid = 67278;
    users.matt = {
      uid = 501;
      extraGroups = [
        "wheel"
        "orbstack"
        "podman"
      ];

      # simulate isNormalUser, but with an arbitrary UID
      isSystemUser = true;
      group = "users";
      createHome = true;
      home = "/home/matt";
      homeMode = "700";
      shell = pkgs.zsh;
      subUidRanges = [
        {
          startUid = 100000;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = 100000;
          count = 65536;
        }
      ];
    };
  };

  security = {
    sudo.wheelNeedsPassword = false;
    pki.certificates = [
      ''
              -----BEGIN CERTIFICATE-----
        MIICDDCCAbOgAwIBAgIRAJvBHpFFPQmbaXICB/1zpfwwCgYIKoZIzj0EAwIwZjEd
        MBsGA1UEChMUT3JiU3RhY2sgRGV2ZWxvcG1lbnQxHjAcBgNVBAsMFUNvbnRhaW5l
        cnMgJiBTZXJ2aWNlczElMCMGA1UEAxMcT3JiU3RhY2sgRGV2ZWxvcG1lbnQgUm9v
        dCBDQTAeFw0yMzExMjkyMDU1NDhaFw0zMzExMjkyMDU1NDhaMGYxHTAbBgNVBAoT
        FE9yYlN0YWNrIERldmVsb3BtZW50MR4wHAYDVQQLDBVDb250YWluZXJzICYgU2Vy
        dmljZXMxJTAjBgNVBAMTHE9yYlN0YWNrIERldmVsb3BtZW50IFJvb3QgQ0EwWTAT
        BgcqhkjOPQIBBggqhkjOPQMBBwNCAAQEIqoj7w9u9cDkN/8Buy9OD827MhkO581r
        luP72D8+mEeNg1WM6flZij1mZZi7mSnrq9zG/MGerlxOebnX+dCSo0IwQDAOBgNV
        HQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUjU/MvCJQwtRF
        5FC+3U6c6pXM3PYwCgYIKoZIzj0EAwIDRwAwRAIge7D6x+whGHEQhwwSA8c7tVFQ
        oMFCOzBfkHLIER89Jp8CIC/rA34NIhKv0iFOVp230K63ENv13SfErnQj2YsRH4MH
        -----END CERTIFICATE-----

        -----BEGIN CERTIFICATE-----
        MIIB+zCCAYCgAwIBAgIJAOmnrpSmpkDHMAoGCCqGSM49BAMDMDAxEjAQBgNVBAoM
        CUROU0ZpbHRlcjEaMBgGA1UEAwwRRE5TRmlsdGVyIFJvb3QgQ0EwHhcNMTcxMTA5
        MjMyMDI5WhcNMzcxMTA0MjMyMDI5WjAwMRIwEAYDVQQKDAlETlNGaWx0ZXIxGjAY
        BgNVBAMMEUROU0ZpbHRlciBSb290IENBMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE
        OXmRoYaUunupYevaDz3amvJJncDKx9q9xpWPSpUd9HmDMbTTJCXyjIwBcfZvMkST
        uoJ85PzI/OxbKTBL4Ju3xeyedZJoQDQC2kGdw2/7AAuEJ5qX/H8eTYgd/U0HZptL
        o2YwZDAdBgNVHQ4EFgQUOOmtJ8Qr1M4Q4NlnTRQdhOJm7vUwHwYDVR0jBBgwFoAU
        OOmtJ8Qr1M4Q4NlnTRQdhOJm7vUwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8B
        Af8EBAMCAYYwCgYIKoZIzj0EAwMDaQAwZgIxAP21roVYzTcLue2zEXkt6UGftv0O
        jitFCWV4/jWVIZg9jJd2y/RS58QTMPaWUSyInQIxAO8WYt/eZeLgEE82jBHtTCN1
        exKSEHwaLmwXlOXBY0b+7youkJRXvXtyitUJ2HjvVw==
        -----END CERTIFICATE-----

        -----BEGIN CERTIFICATE-----
        MIIB/TCCAYKgAwIBAgIJAIjA3MFIFD3cMAoGCCqGSM49BAMDMDExEjAQBgNVBAoM
        CU5ldEFsZXJ0czEbMBkGA1UEAwwSTmV0QWxlcnRzIFNlcnZpY2VzMB4XDTE3MTEw
        OTIyMzMwNloXDTM3MTEwNDIyMzMwNlowMTESMBAGA1UECgwJTmV0QWxlcnRzMRsw
        GQYDVQQDDBJOZXRBbGVydHMgU2VydmljZXMwdjAQBgcqhkjOPQIBBgUrgQQAIgNi
        AARC6ePbI7jqGDpBSxHzV662SWoO4OCqoGoNdL6tUjhDxim/iR7P5zp5vVun52z+
        zv13Hdc6HtW1C5qrwW17QkSeQ9LXnRJg7AAa5b2ZYXIUhr2OEKnj+nGglKmCwkU1
        PCqjZjBkMB0GA1UdDgQWBBT3xkSnEXGakAgJo2QmKDiPVNpYvzAfBgNVHSMEGDAW
        gBT3xkSnEXGakAgJo2QmKDiPVNpYvzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1Ud
        DwEB/wQEAwIBhjAKBggqhkjOPQQDAwNpADBmAjEA1Et99GfPupouMMNALH9Cn+LX
        1YGWgbnTFNqEbfmtpPmphF3qRhrVb4WNawXAd9e2AjEAsPch3yXzpGGGqdhRzq0r
        KJLxvMMDYFbSwfotJ4Lqd4Kvb/9qFLLOoOgcQusYIhoT
        -----END CERTIFICATE-----

        -----BEGIN CERTIFICATE-----
        MIIEtjCCAx6gAwIBAgIRAN5yjKWioISVeLgQcrYDJXIwDQYJKoZIhvcNAQELBQAw
        czEeMBwGA1UEChMVbWtjZXJ0IGRldmVsb3BtZW50IENBMSQwIgYDVQQLDBttYXR0
        QE1hdHRzLU1CUC5sb2NhbCAoTWF0dCkxKzApBgNVBAMMIm1rY2VydCBtYXR0QE1h
        dHRzLU1CUC5sb2NhbCAoTWF0dCkwHhcNMjMwMjA2MTczNDM1WhcNMzMwMjA2MTcz
        NDM1WjBzMR4wHAYDVQQKExVta2NlcnQgZGV2ZWxvcG1lbnQgQ0ExJDAiBgNVBAsM
        G21hdHRATWF0dHMtTUJQLmxvY2FsIChNYXR0KTErMCkGA1UEAwwibWtjZXJ0IG1h
        dHRATWF0dHMtTUJQLmxvY2FsIChNYXR0KTCCAaIwDQYJKoZIhvcNAQEBBQADggGP
        ADCCAYoCggGBAOY9S7qtQqujjSI5D8po8WoejdwTWkRnW5ZS05YwUj3EVbHh+Wav
        shkwMNObrXGciLScgkRUgbo8Yoz9P9IsqXHXNmR40y8V29/x4dx+io7jqwH/lyyy
        dnXiFsY3ivNb1Z8XHnUrHLv5/ZXfw1WhIr60f09JhWfA5Ycf6XBSQiRDMVcF/wbX
        Yq2M7MaW2hKC9HLaaslNj8IMkQqkVq/N7YZDf05x3DcqtZvMeEFkjzwbFuIj/oqR
        Y3+HGwhuNus0nnSABqCgmPKl3m9mgvhcMTWdCjFKBjItUQOGt50XVIrt7AeGnrbs
        oy9OR1VLiRpNM2GQ1JprUbbZZ+fD1hE1x1diaie1lcLCSimTmTnb31sPly8/10f6
        vb7qCymXhlbVvyuu85YyEKHAm2rrx/7RhMtQ6izsWXhcbii7uaLs5lsZUOvj3Ybc
        HKUsN3oqQrEKnJxvkVEOpraH2jXjTMyF6qnD5odHtlIrKI86Lt5JG/RWDwNAb5Tv
        h9N63UkwGKQ4cwIDAQABo0UwQzAOBgNVHQ8BAf8EBAMCAgQwEgYDVR0TAQH/BAgw
        BgEB/wIBADAdBgNVHQ4EFgQU4DFjCByZePzPBlJna7IpxT6sQUQwDQYJKoZIhvcN
        AQELBQADggGBAHiYaXV7aOKWgF0klftf50FFeRrOtO7SYnFhIklA3HOycEsnH2HM
        wMc9kiVmM8+2rzYFGfvZHZRWHZJnXV1vH1fqD8+H3hKZ456+7Np9tT5MWmMzn0Q0
        5mkADUqomIkgRzGL6MYwZyQbMKQRcLbrVeu+xxifEk39Bb/sid1MSRfD0p8+Utno
        rAFIIrpFyfFmwiwr0n1TD/V1lAvWDN7QP61RoWETNoLZY0wAdCaVhon3LyY/DRJC
        7/G3Faad1JWXj5EJRzbY8bIXXINQbd7I7YAfZ17kpdK22ZZ+GdlMi9KkwBcYYfvw
        cfP/tqa8BgPxd6lZbwdHCuL7GtMqhejqdqu6ElNgeVhOrpWp+5vJ4htBPzjMTJTs
        9N+MJ2Ro3/VYLR4a23X0HFQq3PSflUWGlDXM/5Y4b748/TUKqa4ouoi61oY3YHMb
        z4YmRKVssUFsQM1W7GWET+l9lhqtcjfadPksVnyzyVOGSwdVGvDSWJ2pGTSiJZAx
        EX8sojCWxpv7Gg==
        -----END CERTIFICATE-----

        -----BEGIN CERTIFICATE-----
        MIICDDCCAbOgAwIBAgIRAJvBHpFFPQmbaXICB/1zpfwwCgYIKoZIzj0EAwIwZjEd
        MBsGA1UEChMUT3JiU3RhY2sgRGV2ZWxvcG1lbnQxHjAcBgNVBAsMFUNvbnRhaW5l
        cnMgJiBTZXJ2aWNlczElMCMGA1UEAxMcT3JiU3RhY2sgRGV2ZWxvcG1lbnQgUm9v
        dCBDQTAeFw0yMzExMjkyMDU1NDhaFw0zMzExMjkyMDU1NDhaMGYxHTAbBgNVBAoT
        FE9yYlN0YWNrIERldmVsb3BtZW50MR4wHAYDVQQLDBVDb250YWluZXJzICYgU2Vy
        dmljZXMxJTAjBgNVBAMTHE9yYlN0YWNrIERldmVsb3BtZW50IFJvb3QgQ0EwWTAT
        BgcqhkjOPQIBBggqhkjOPQMBBwNCAAQEIqoj7w9u9cDkN/8Buy9OD827MhkO581r
        luP72D8+mEeNg1WM6flZij1mZZi7mSnrq9zG/MGerlxOebnX+dCSo0IwQDAOBgNV
        HQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUjU/MvCJQwtRF
        5FC+3U6c6pXM3PYwCgYIKoZIzj0EAwIDRwAwRAIge7D6x+whGHEQhwwSA8c7tVFQ
        oMFCOzBfkHLIER89Jp8CIC/rA34NIhKv0iFOVp230K63ENv13SfErnQj2YsRH4MH
        -----END CERTIFICATE-----

      ''
    ];
  };

  documentation = {
    man.enable = true;
    doc.enable = true;
    info.enable = true;
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      settings = {
        global = {
          bash_path = "${pkgs.bash}/bin/bash";
          hide_env_diff = true;
          strict_env = true;
          warn_timeout = "1m";
        };
      };
    };
    zsh.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        xz
        openssl
        libcap
      ];
    };
    ssh.extraConfig = ''
      Include /opt/orbstack-guest/etc/ssh_config
    '';
  };

  services = {
    resolved.enable = false;
    openssh.enable = false;
  };

  systemd = {
    network = {
      enable = true;
      networks."50-eth0" = {
        matchConfig.Name = "eth0";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
    services = {
      "systemd-oomd".serviceConfig.WatchdogSec = 0;
      "systemd-userdbd".serviceConfig.WatchdogSec = 0;
      "systemd-udevd".serviceConfig.WatchdogSec = 0;
      "systemd-timesyncd".serviceConfig.WatchdogSec = 0;
      "systemd-timedated".serviceConfig.WatchdogSec = 0;
      "systemd-portabled".serviceConfig.WatchdogSec = 0;
      "systemd-nspawn@".serviceConfig.WatchdogSec = 0;
      "systemd-machined".serviceConfig.WatchdogSec = 0;
      "systemd-localed".serviceConfig.WatchdogSec = 0;
      "systemd-logind".serviceConfig.WatchdogSec = 0;
      "systemd-journald@".serviceConfig.WatchdogSec = 0;
      "systemd-journald".serviceConfig.WatchdogSec = 0;
      "systemd-journal-remote".serviceConfig.WatchdogSec = 0;
      "systemd-journal-upload".serviceConfig.WatchdogSec = 0;
      "systemd-importd".serviceConfig.WatchdogSec = 0;
      "systemd-hostnamed".serviceConfig.WatchdogSec = 0;
      "systemd-homed".serviceConfig.WatchdogSec = 0;
      "systemd-networkd".serviceConfig.WatchdogSec = lib.mkIf config.systemd.network.enable 0;
    };
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  nix = {
    settings = {
      sandbox = false;
      extra-substituters = nixSettings.substituters;
      extra-trusted-public-keys = nixSettings.trustedPublicKeys;
      trusted-users = nixSettings.trustedUsers;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-platforms = [
        "x86_64-linux"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  fileSystems."/Users/matt/code" = {
    device = "/mnt/mac/Users/matt/code";
    fsType = "none";
    options = [ "bind" ];
  };
}
