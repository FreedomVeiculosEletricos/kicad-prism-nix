{
  lib,
  buildNpmPackage,
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
