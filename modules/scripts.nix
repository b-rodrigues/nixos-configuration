#===============================================================================
# Shell-script packages shared by both hosts, installed system-wide.
#
# The script bodies live as plain .sh files in ./scripts (real files: syntax
# highlighting, shellcheck-able, clean diffs). Each wrapper prepends a PATH
# built from the packages the script needs when run outside a login session,
# then falls back to the running session's PATH.
#===============================================================================

{
  pkgs,
  lib,
  ...
}:

let
  script =
    name: bins:
    if bins == [ ] then
      pkgs.writeShellScriptBin name (builtins.readFile (./scripts + "/${name}.sh"))
    else
      pkgs.writeShellScriptBin name (lib.concatStringsSep "\n" [
        "export PATH=${lib.makeBinPath bins}:$PATH"
        (builtins.readFile (./scripts + "/${name}.sh"))
      ]);
in
{
  environment.systemPackages = [
    (script "nixpr-review" [ pkgs.curl ])
    (script "grimshot-menu" [ pkgs.coreutils ])
    (script "clipboard-menu" [ ])
    (script "clipboard-clear" [ ])
    (script "rofi-files" [ pkgs.fd ])
    (script "rofi-grep" [ pkgs.ripgrep ])
    (script "tg" [
      pkgs.curl
      pkgs.jq
    ])
    (script "llm" [ pkgs.jq ])
  ];
}
