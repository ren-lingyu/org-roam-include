{ lib, runCommand, replaceVarsWith, guile, emacs }:
runCommand "org-roam-include-ert"
  { nativeBuildInputs = [ emacs guile ]; }
  (builtins.toString (replaceVarsWith {
    name = "org-roam-include-ert-runner";
    src = ./run.scm;
    replacements = {
      emacs = lib.getExe' emacs "emacs";
      guile = lib.getExe guile;
      testFile = "${./ert.el}";
    };
    isExecutable = true;
  }))
