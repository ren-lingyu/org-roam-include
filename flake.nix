{
  description = "Emacs package: org-roam-include";

  inputs = {
    nixpkgs = {
      url = "git+https://github.com/NixOS/nixpkgs.git?ref=refs/heads/nixpkgs-unstable&shallow=1";
    };
    personal-nixpkgs = {
      url = "git+https://github.com/ren-lingyu/nixpkgs.git?ref=refs/heads/main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.personal-nixpkgs.lib.mkFlake inputs.nixpkgs
      ({ lib }: rec {
        inherit inputs;
        moduleLocation = __curPos.file;
        llib = inputs.personal-nixpkgs.lib.mergeAttrsRecursive { allowOverrides = false; } [
          { inherit (inputs.personal-nixpkgs.lib) tests packages; }
        ];
        lpkgs = import ./pkgs {
          inherit llib;
          inherit (specialArgs) src;
        };
        specialArgs = {
          src = lib.fileset.toSource {
            root = ./lisp;
            fileset = ./lisp;
          };
        };
      })
      (
        {
          src,
          llib,
          lpkgs,
          ...
        }:
        {
          systems = inputs.nixpkgs.lib.systems.flakeExposed;

          perSystem =
            { pkgs, ... }:
            let
              emacsPackages = pkgs.emacsPackagesFor pkgs.emacs31;
            in
            {
              nixpkgs.overlays = [ lpkgs.overlays.legacy ];

              legacyPackages = pkgs.legacyPackages;

              packages = {
                default = emacsPackages.org-roam-include;
                org-roam-include = emacsPackages.org-roam-include;
                emacs = pkgs.emacs-with-org-roam-include;
              };

              checks = import ./tests {
                inherit src pkgs llib;
                emacs = pkgs.emacs-with-org-roam-include;
              };

              devShells.default = pkgs.mkShell { packages = [ pkgs.emacs-with-org-roam-include ]; };

              treefmt = {
                flakeCheck = false;
                settings.excludes = [
                  "*.patch"
                  ".gitignore"
                  "LICENSE"
                  "README.org"
                  "flake.lock"
                ];
              };
            };
        }
      );
}
