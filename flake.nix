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
    flake-parts.lib.mkFlake { inherit inputs; } ({ moduleWithSystem, ... }: {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        {
          packages.default = (poetry2nix.lib.mkPoetry2Nix {
            inherit pkgs;
          }).mkPoetryApplication {
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

      flake = {
        nixosModules.default =
          moduleWithSystem
            (
              perSystem@{ config }:
              { lib, ... }: {
                imports = [
                  ({ lib, config, ... }:
                    with lib;
                    let
                      cfg = config.services.online-keeper;
                    in
                    {
                      options.services.online-keeper = {
                        instances = mkOption {
                          type = types.listOf (types.submodule {
                            options = {
                              name = mkOption { type = types.str; };
                              package = mkPackageOption perSystem.config.packages "default" { };
                              environmentFile = mkOption { type = types.str; default = ""; };
                            };
                          });
                          default = [ ];
                        };
                      };
                      config =
                        mkIf (cfg.instances != [ ])
                          {
                            environment.systemPackages = lib.unique (lib.foldr
                              (s: acc: acc ++ [ s.package ]) [ ]
                              cfg.instances);

                            systemd.services = lib.foldr
                              (s: acc: acc // {
                                "online-keeper-${s.name}" = {
                                  wantedBy = [ "multi-user.target" ];
                                  after = [ "network-online.target" ];
                                  wants = [ "network-online.target" ];
                                  description = "telegram online-keeper daemon";
                                  serviceConfig = {
                                    DynamicUser = true;
                                    StateDirectory = "online-keeper";
                                    ExecStart = lib.getExe' s.package "online-keeper";
                                    EnvironmentFile = s.environmentFile;
                                    Restart = "on-failure";
                                  };
                                };
                              })
                              { }
                              cfg.instances;
                          };
                    })
                ];

              }

            );
      };
    });
}
