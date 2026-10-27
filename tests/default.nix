{
  pkgs,
  src,
  emacs,
  llib,
}:
llib.tests.mkChecks {
  root = ./.;
  overlayFile = "test-overlay.nix";
  separator = "-";
  args = {
    inherit (pkgs)
      lib
      runCommand
      replaceVarsWith
      guile
      ;
    inherit src emacs;
    emacsPackages = pkgs.emacsPackagesFor pkgs.emacs31;
  };
}
