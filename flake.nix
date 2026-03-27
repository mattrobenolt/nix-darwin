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
    }:
    {
      # ============================================================================
      # macOS Systems (nix-darwin)
      # ============================================================================

      darwinConfigurations = {
        # Work MacBook Pro
        "Matts-MacBook-Pro" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit mattware llm-agents; };
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
        nixos = nixpkgs.lib.nixosSystem {
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
              };
            }
          ];
        };
      };
    };
}
