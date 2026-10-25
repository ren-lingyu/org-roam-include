{ lib, runCommand, replaceVarsWith, guile, src, emacs }:
runCommand "org-roam-include-package-lint"
  { nativeBuildInputs = [ emacs guile ]; }
  (builtins.toString (replaceVarsWith {
    name = "org-roam-include-package-lint-runner";
    src = ./run.scm;
    replacements = {
      emacs = lib.getExe' emacs "emacs";
      guile = lib.getExe guile;
      source = "${src}";
    };
    isExecutable = true;
  }))
