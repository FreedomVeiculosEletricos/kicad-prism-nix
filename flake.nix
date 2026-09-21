{
  description = "Nix packaging for KiCad Prism — packages, overlay and NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # main tracks upstream dev; release.yml re-points this at a tag.
    kicad-prism = {
      url = "github:krishna-swaroop/KiCAD-Prism/dev";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      # flake.lock is part of this flake's source, so the pin is readable at
      # eval time. This is where the package version comes from.
      upstreamRef = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.kicad-prism.original.ref;

      # The overlay is the source of truth; nix/packages re-exports it.
      overlay = import ./nix/overlay.nix {
        src = inputs.kicad-prism;
        ref = upstreamRef;
        inherit (inputs.kicad-prism) lastModifiedDate;
      };
    in
    inputs.blueprint {
      inherit inputs;
      prefix = "nix/";
      systems = [ "x86_64-linux" ];
      nixpkgs.overlays = [ overlay ];
    }
    // {
      overlays.default = overlay;

      # blueprint hands modules out as paths, which `nix flake check` rejects.
      nixosModules.default = import ./nix/modules/nixos/default.nix;
    };
}
