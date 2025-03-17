{
  description = "flake for this";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    naersk.url = "github:nix-community/naersk";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      naersk,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { moduleWithSystem, ... }:
      {
        imports = [
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        perSystem =
          {
            pkgs,
            ...
          }:
          {
            packages = rec {
              default = rust;

              rust =
                let
                  naersk' = pkgs.callPackage naersk { };
                in
                naersk'.buildPackage {
                  src = ./.;
                };
            };

          };

        flake = {
          nixosModules.default = moduleWithSystem (
            perSystem@{ config }:
            nixos@{ lib, ... }:
            with lib;
            let
              cfg = nixos.config.services.online-keeper;
            in
            {
              options.services.online-keeper = {
                instances = mkOption {
                  type = types.attrsOf (
                    types.submodule {
                      options = {
                        package = mkPackageOption perSystem.config.packages "default" { };
                        sessionFile = mkOption {
                          type = types.str;
                          default = "";
                        };
                        environmentFile = mkOption {
                          type = types.str;
                          default = "";
                        };
                      };
                    }
                  );
                  default = [ ];
                };
              };
              config = mkIf (cfg.instances != [ ]) {
                systemd.services = lib.mapAttrs' (
                  name: opts:
                  nameValuePair name {
                    wantedBy = [ "multi-user.target" ];
                    after = [ "network-online.target" ];
                    wants = [ "network-online.target" ];
                    description = "telegram online-keeper daemon for ${name}";
                    serviceConfig = {
                      DynamicUser = true;
                      LoadCredential = [ "session:${opts.sessionFile}" ];
                      Environment = [ "SESSION_FILE=/run/credentials/online-keeper-${name}.service/session" ];
                      EnvironmentFile = opts.environmentFile;
                      ExecStart = lib.getExe' opts.package "tg-online-keeper";
                      Restart = "on-failure";
                    };
                  }
                ) cfg.instances;
              };
            }
          );
        };
      }
    );
}
