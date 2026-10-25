{ }: final_: prev_: {
  emacs-with-org-roam-include = final_.callPackage ./package.nix { emacs = final_.emacs31; };
}
