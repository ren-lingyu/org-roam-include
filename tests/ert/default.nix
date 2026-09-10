{ pkgs, emacs } : (

  pkgs.runCommand "org-roam-include-ert" {
    nativeBuildInputs = [
      emacs
      pkgs.guile
    ];
  } (builtins.toString (pkgs.replaceVarsWith {
    name = "org-roam-include-ert-runner";
    src = ./run.scm;
    replacements = {
      emacs = pkgs.lib.getExe' emacs "emacs";
      guile = pkgs.lib.getExe pkgs.guile;
      testFile = "${./ert.el}";
    };
    isExecutable = true;
  }))

)
