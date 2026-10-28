{
  lib,
  buildNpmPackage,
  ecad-renderer,
  importNpmLock,
  kicad-prism-viewer,
  sources,
}:

buildNpmPackage (finalAttrs: {
  pname = "kicad-prism-frontend";
  version = sources.version;

  src = sources.kicad-prism-frontend;

  postUnpack = ''
    for path in backend/tests/fixtures fixtures native/contracts; do
      mkdir -p "$(dirname "$path")"
      cp -r --no-preserve=mode ${sources.kicad-prism}/$path $path
    done
  '';

  postPatch = ''
    grep -qF '"adapterCommit": "${ecad-renderer.adapterCommit}"' public/ecad-viewer.manifest.json
    old=$(sha256sum public/ecad-renderer.js | cut -d' ' -f1)
    cp ${ecad-renderer}/ecad-renderer.js public/ecad-renderer.js
    new=$(sha256sum public/ecad-renderer.js | cut -d' ' -f1)
    substituteInPlace src/lib/ecad-renderer-build.ts \
      --replace-fail "ecad-renderer.js?v=$old" "ecad-renderer.js?v=$new"
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
