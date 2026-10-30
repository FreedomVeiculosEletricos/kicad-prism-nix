{
  lastModifiedDate,
  pyproject-nix,
  ref,
  src,
}:
final: prev:
let
  inherit (prev) lib;

  sources = import ./sources.nix {
    inherit
      lastModifiedDate
      lib
      ref
      src
      ;
  };

  upstreamPatches = [
    (final.fetchpatch {
      name = "semantic-index-stale-board-nets.patch";
      url = "https://github.com/krishna-swaroop/KiCAD-Prism/commit/a3d95226eb8068b1d5354422726712b272a33da3.patch";
      excludes = [ "native/Cargo.lock" ];
      hash = "sha256-RPGG8rDYiXtafhYtXG0VAeHhWW3YXfa82EPVA4VjIIc=";
    })
  ];
in
{
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      inline-snapshot = pyprev.inline-snapshot.overridePythonAttrs (_: {
        doCheck = false;
      });

      # KiCad Prism needs a starlette newer than any nixpkgs channel carries.
      starlette = pyprev.starlette.overridePythonAttrs (_: rec {
        version = "1.6.0";
        src = final.fetchFromGitHub {
          owner = "Kludex";
          repo = "starlette";
          tag = version;
          hash = "sha256-Cp6wkRxbDdC+Yf3z4TvRF5xrchJ+PAo36qHbBg+FcXw=";
        };
      });

      kicad-monkey = pyfinal.callPackage ./python-modules/kicad-monkey/package.nix { };
      wn-geometer = pyfinal.callPackage ./python-modules/wn-geometer/package.nix { };
    })
  ];

  ecad-renderer = final.callPackage ./packages/ecad-renderer/package.nix { };

  kicad-prism-frontend = final.callPackage ./packages/kicad-prism-frontend/package.nix {
    inherit sources;
  };

  kicad-prism-viewer = final.callPackage ./packages/kicad-prism-viewer/package.nix {
    inherit sources;
  };

  prism-kicad = final.callPackage ./packages/prism-kicad/package.nix {
    inherit sources upstreamPatches;
  };

  geometer = final.callPackage ./packages/geometer/package.nix { };

  kicad-prism = final.callPackage ./packages/kicad-prism/package.nix {
    inherit pyproject-nix sources upstreamPatches;
  };
}
