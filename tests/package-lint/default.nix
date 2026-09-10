{ pkgs, source, emacs } : (

  pkgs.runCommand "org-roam-include-package-lint" {
    nativeBuildInputs = [
      emacs
      pkgs.guile
    ];
  } (builtins.toString (pkgs.replaceVarsWith {
    name = "org-roam-include-package-lint-runner";
    src = ./run.scm;
    replacements = {
      emacs = pkgs.lib.getExe' emacs "emacs";
      guile = pkgs.lib.getExe pkgs.guile;
      source = "${source}";
    };
    isExecutable = true;
  }))

)
