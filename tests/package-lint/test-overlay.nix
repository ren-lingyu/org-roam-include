{ }: final_: prev_: {
  package-lint = final_.callPackage ./test.nix {
    emacs = final_.emacsPackages.emacsWithPackages (epkgs_: [
      epkgs_.org-roam-include
      epkgs_.package-lint
    ]);
  };
}
