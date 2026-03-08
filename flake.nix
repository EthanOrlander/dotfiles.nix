{
  description = "Ethan's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      mkHome = { system, hostModule }: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [
          ./home/default.nix
          hostModule
        ];
        extraSpecialArgs = { inherit self; };
      };
    in {
      homeConfigurations = {
        "work-macbook" = mkHome {
          system = "aarch64-darwin";
          hostModule = ./home/hosts/work-macbook.nix;
        };
      };
    };
}
