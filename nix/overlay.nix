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

      kiutils = pyfinal.callPackage ./python-modules/kiutils/package.nix { };
      kicad-monkey = pyfinal.callPackage ./python-modules/kicad-monkey/package.nix { };
      kicad-cruncher = pyfinal.callPackage ./python-modules/kicad-cruncher/package.nix { };
      wn-geometer = pyfinal.callPackage ./python-modules/wn-geometer/package.nix { };
    })
  ];

  kicad-prism-frontend = final.callPackage ./packages/kicad-prism-frontend/package.nix {
    inherit sources;
  };

  kicad-prism-viewer = final.callPackage ./packages/kicad-prism-viewer/package.nix {
    inherit sources;
  };

  prism-clipper2 = final.callPackage ./packages/prism-clipper2/package.nix {
    inherit sources;
  };

  kicad-prism = final.callPackage ./packages/kicad-prism/package.nix {
    inherit pyproject-nix sources;
  };
}
