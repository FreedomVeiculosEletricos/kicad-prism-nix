{
  lib,
  buildNpmPackage,
  fetchpatch,
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

  patches = [
    (fetchpatch {
      name = "draw-visible-symbol-fields.patch";
      url = "https://github.com/krishna-swaroop/ecad-viewer/commit/e5da870b640941a7e7d78d7f50663ec4b90c95b3.patch";
      hash = "sha256-dXZoZkFuaPE/L4vXqfQUZTx9QN3iLSYLeNmKvyuMkpY=";
    })
    (fetchpatch {
      name = "size-pad-paste-and-mask-openings.patch";
      url = "https://github.com/krishna-swaroop/ecad-viewer/commit/b541155be98b602e0778492aa09ebe9f6d853d67.patch";
      hash = "sha256-YyBsrxqPhcU2Fc/tuQRgvqfWvtwNgcoGUKClV+koEZ4=";
    })
    # https://github.com/krishna-swaroop/ecad-viewer/pull/80
    (fetchpatch {
      name = "report-custom-layer-names.patch";
      url = "https://github.com/krishna-swaroop/ecad-viewer/commit/2e224521661fc7a71aad008981ec3b42ff1525fd.patch";
      hash = "sha256-qHFqWY8bnL72bPYSMby4Gs7j4KzrqB84d/0r6YodLok=";
    })
    # https://github.com/krishna-swaroop/ecad-viewer/pull/81
    (fetchpatch {
      name = "fill-board-body-inside-edge-cuts.patch";
      url = "https://github.com/krishna-swaroop/ecad-viewer/commit/7265f06bf5567b0acd4ae0f80b58ac4633aca943.patch";
      hash = "sha256-9xGUd6DKMi7aSrcGj/vXHTWXHf+PX+167KMcHRQxjys=";
    })
  ];

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
