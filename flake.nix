{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mattware.url = "github:mattrobenolt/nixpkgs";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    llm-agents.url = "github:numtide/llm-agents.nix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    # Desktop PC (nixos) inputs
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
    zed.url = "github:zed-industries/zed/v0.228.0-pre";
    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
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
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            just
            nixfmt
            statix
            deadnix
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
        # OrbStack VM (aarch64-linux, shares filesystem with Mac)
        orbstack = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./hosts/nixos/orbstack/default.nix

            # Apply llm-agents overlay so pkgs.llm-agents.* is available
            { nixpkgs.overlays = [ llm-agents.overlays.default ]; }

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
                llm-agents.overlays.default
                (final: prev: {
                  ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;
                  zed-editor = inputs.zed.packages.${prev.stdenv.hostPlatform.system}.default;
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
