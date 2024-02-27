{
  description = "flake for this";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, devenv, poetry2nix, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryApplication;
        in
        {
          packages.default = mkPoetryApplication {
            projectDir = ./.;
          };

          # broken `nix flake show` but doesn't matter.
          devenv.shells.default = {
            languages.python = {
              enable = true;
              poetry.enable = true;
            };

            dotenv.enable = true;
            enterShell = ''
              export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib"
            '';
          };
        };
    };
}
