{
  lib,
  buildNpmPackage,
  importNpmLock,
  sources,
}:

buildNpmPackage (finalAttrs: {
  pname = "ecad-renderer";
  version = "0-unstable-${
    lib.concatStringsSep "-" [
      (builtins.substring 0 4 sources.ecad-viewer.lastModifiedDate)
      (builtins.substring 4 2 sources.ecad-viewer.lastModifiedDate)
      (builtins.substring 6 2 sources.ecad-viewer.lastModifiedDate)
    ]
  }";

  src = sources.ecad-viewer;

  npmDeps = importNpmLock {
    npmRoot = finalAttrs.src;
  };
  npmConfigHook = importNpmLock.npmConfigHook;

  npmFlags = [ "--ignore-scripts" ];

  buildPhase = ''
    runHook preBuild
    node packages/ecad-viewer-app/scripts/build.js
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 packages/ecad-viewer-app/build/ecad-renderer.js $out/ecad-renderer.js
    install -Dm644 packages/ecad-viewer-app/build/ecad-viewer.js $out/ecad-viewer.js
    runHook postInstall
  '';

  passthru.adapterCommit = sources.ecad-viewer.rev;

  meta = {
    description = "Standalone KiCad symbol and footprint renderer from ECAD Viewer";
    homepage = "https://github.com/krishna-swaroop/ecad-viewer";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
})
