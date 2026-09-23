{ inputs, pkgs, ... }:
inputs.treefmt-nix.lib.mkWrapper pkgs {
  imports = [ inputs.pedantix.treefmtModules.default ];

  projectRootFile = "flake.nix";

  programs.pedantix.enable = true;
}
