{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mattware.url = "github:mattrobenolt/nixpkgs";
    porthole.url = "github:mattrobenolt/porthole";
    home-manager.url = "github:nix-community/home-manager";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    herdr.url = "github:herdrdev/herdr/v0.8.2";
    # Agent mission-control terminal (luvus.dev). Tracks upstream main;
    # `just update` bumps it. Upstream's darwin sqlite fix landed
    # (RizRiyz/luvus#196), so their flake package builds on both hosts.
    # `luvus update` never overwrites a nix-installed binary — it reports
    # the package-manager action instead.
    luvus.url = "github:RizRiyz/luvus/v0.13.4";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprpolkitagent = {
      url = "github:hyprwm/hyprpolkitagent";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprsunset = {
      url = "github:hyprwm/hyprsunset";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };
    hyprshell = {
      url = "github:H3rmt/hyprshell";
      inputs.hyprland.follows = "hyprland";
    };

    ghostty.url = "github:ghostty-org/ghostty";
    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      mattware,
      nix-darwin,
      home-manager,
      llm-agents,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      llmAgentsRtkOverlay = final: _prev: {
        inherit (final.llm-agents) rtk;
      };
      # luvus (luvus.dev) from the upstream flake input (tracks main).
      # Their packaging wraps git/gh/ssh/procps into the binary's PATH —
      # matters on NixOS hosts with no global PATH.
      luvusOverlay = _final: prev: {
        luvus = inputs.luvus.packages.${prev.stdenv.hostPlatform.system}.default;
      };
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages =
            with nixpkgs.legacyPackages.${system};
            [
              deadnix
              fd
              gum
              just
              lua5_4
              nixfmt
              nixos-rebuild
              nushell
              opentofu
              statix
              awscli2
            ]
            ++ [
              # the nixpkgs attr doesn't exist under this name; use the input's
              # own package so CLI and module versions match.
              inputs.agenix.packages.${system}.default
            ];
        };
      });
      # ============================================================================
      # macOS Systems (nix-darwin)
      # ============================================================================

      darwinConfigurations = {
        # Work MacBook Pro
        "Matts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs mattware llm-agents; };
          modules = [
            # Shared config (common packages, settings)
            ./common.nix

            {
              nixpkgs.overlays = [
                llm-agents.overlays.shared-nixpkgs
                llmAgentsRtkOverlay
                luvusOverlay
              ];
            }

            # Host-specific config
            ./hosts/darwin/work.nix

            # Set git commit hash for darwin-version
            {
              system.configurationRevision = self.rev or self.dirtyRev or null;
            }

            # home-manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.matt = import ./home.nix;
                extraSpecialArgs = { inherit inputs; };
                # Disable home-manager's nix management when system nix is disabled
                sharedModules = [
                  { nix.enable = false; }
                ];
              };
            }
          ];
        };
      };

      # ============================================================================
      # NixOS Systems
      # ============================================================================

      nixosConfigurations = {
        # EC2 agent box (aarch64-linux, playground account, us-west-2).
        # Infra lives in infra/launchpad/; bring-up runbook in
        # infra/launchpad/README.md.
        launchpad = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            inputs.agenix.nixosModules.default
            ./hosts/nixos/launchpad/default.nix

            {
              nixpkgs.overlays = [
                llm-agents.overlays.shared-nixpkgs
                mattware.overlays.default
                llmAgentsRtkOverlay
                luvusOverlay
              ];
            }

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                # Agent tools write their own config files into HM-managed
                # paths (herdr did); back up rather than fail activation.
                backupFileExtension = "backup";
                users.matt = import ./hosts/nixos/launchpad/home.nix;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };

        # OrbStack VM (aarch64-linux, shares filesystem with Mac)
        orbstack = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/nixos/orbstack/default.nix

            # Apply package overlays used by home-manager and system packages
            {
              nixpkgs.overlays = [
                llm-agents.overlays.shared-nixpkgs
                mattware.overlays.default
                llmAgentsRtkOverlay
              ];
            }

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.matt = import ./hosts/nixos/orbstack/home.nix;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };

        # Desktop PC (x86_64-linux)
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nixos/nixos/default.nix

            {
              nixpkgs.overlays = [
                llm-agents.overlays.shared-nixpkgs
                mattware.overlays.default
                (_final: prev: {
                  ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;
                  helium = inputs.helium.packages.${prev.stdenv.hostPlatform.system}.default;
                  hyprshell = inputs.hyprshell.packages.${prev.stdenv.hostPlatform.system}.default;
                  hyprlock = inputs.hyprlock.packages.${prev.stdenv.hostPlatform.system}.default;
                  hypridle = inputs.hypridle.packages.${prev.stdenv.hostPlatform.system}.default;
                  hyprpolkitagent = inputs.hyprpolkitagent.packages.${prev.stdenv.hostPlatform.system}.default;
                  hyprsunset = inputs.hyprsunset.packages.${prev.stdenv.hostPlatform.system}.default;
                })
              ];
            }

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.matt = import ./hosts/nixos/nixos/home;
                extraSpecialArgs = { inherit inputs; };
              };
            }
          ];
        };
      };
    };
}
