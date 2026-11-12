{
  lib,
  buildNpmPackage,
  ecad-renderer,
  fetchpatch,
  importNpmLock,
  kicad-prism-viewer,
  sources,
}:

buildNpmPackage (finalAttrs: {
  pname = "kicad-prism-frontend";
  version = sources.version;

  src = sources.kicad-prism-frontend;

  # The viewer bundles, manifest and cache keys in these patches are left out:
  # postPatch rebuilds them from ecad-renderer, which carries the viewer side.
  patches = [
    # https://github.com/krishna-swaroop/KiCAD-Prism/pull/1193
    (fetchpatch {
      name = "show-custom-layer-names.patch";
      url = "https://github.com/krishna-swaroop/KiCAD-Prism/commit/de4fee15d26e8106548b010ca817968561ed328d.patch";
      relative = "frontend";
      excludes = [
        "index.html"
        "public/*"
        "src/lib/ecad-renderer-build.ts"
      ];
      hash = "sha256-WJ38Z81NvCi9Jj8RCqizb5h8wG3CiQLIXB1o85/nNlw=";
    })
    # https://github.com/krishna-swaroop/KiCAD-Prism/pull/1194
    (fetchpatch {
      name = "group-pcb-layers.patch";
      url = "https://github.com/krishna-swaroop/KiCAD-Prism/commit/d437d430e1414e74f33919856d8bf9b1c7500159.patch";
      relative = "frontend";
      hash = "sha256-TDnE2TYn1fZKK8P170eGWViw4eBEYMGdsjtQvfGSEcY=";
    })
  ];

  postUnpack = ''
    for path in backend/tests/fixtures fixtures native/contracts; do
      mkdir -p "$(dirname "$path")"
      cp -r --no-preserve=mode ${sources.kicad-prism}/$path $path
    done
  '';

  postPatch = ''
    grep -qF '"adapterCommit": "${ecad-renderer.adapterCommit}"' public/ecad-viewer.manifest.json || {
      echo "ecad-renderer is built from ${ecad-renderer.adapterCommit}, but public/ecad-viewer.manifest.json expects $(grep -o '"adapterCommit": "[^"]*"' public/ecad-viewer.manifest.json)" >&2
      exit 1
    }
    old=$(sha256sum public/ecad-renderer.js | cut -d' ' -f1)
    cp ${ecad-renderer}/ecad-renderer.js public/ecad-renderer.js
    new=$(sha256sum public/ecad-renderer.js | cut -d' ' -f1)
    substituteInPlace src/lib/ecad-renderer-build.ts \
      --replace-fail "ecad-renderer.js?v=$old" "ecad-renderer.js?v=$new"
    substituteInPlace public/ecad-viewer.manifest.json \
      --replace-fail "sha256:$old" "sha256:$new"
    old=$(sha256sum public/ecad-viewer.js | cut -d' ' -f1)
    cp ${ecad-renderer}/ecad-viewer.js public/ecad-viewer.js
    new=$(sha256sum public/ecad-viewer.js | cut -d' ' -f1)
    substituteInPlace index.html \
      --replace-fail "ecad-viewer.js?v=$old" "ecad-viewer.js?v=$new"
    substituteInPlace public/ecad-viewer.manifest.json \
      --replace-fail "sha256:$old" "sha256:$new"
  '';

  npmDeps = importNpmLock {
    npmRoot = sources.kicad-prism-frontend;
  };
  npmConfigHook = importNpmLock.npmConfigHook;

  npmBuildScript = "build";

  preBuild = ''
    cp ${kicad-prism-viewer.semanticViewerBundle} public/prism-semantic-viewer.js
  '';

  postBuild = ''
    npm run build:panel
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    npm test
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/kicad-prism
    cp -r dist $out/share/kicad-prism/frontend
    mv $out/share/kicad-prism/frontend/remote_provider $out/share/kicad-prism/remote-provider

    runHook postInstall
  '';

  meta = {
    description = "Web frontend and KiCad remote provider panel for KiCad Prism";
    homepage = "https://github.com/krishna-swaroop/KiCAD-Prism";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
})
