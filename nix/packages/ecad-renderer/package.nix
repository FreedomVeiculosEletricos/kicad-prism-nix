{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchpatch,
  importNpmLock,
}:

buildNpmPackage (finalAttrs: {
  pname = "ecad-renderer";
  version = "0-unstable-2026-10-23";

  src = fetchFromGitHub {
    owner = "krishna-swaroop";
    repo = "ecad-viewer";
    rev = "ab038d9fe95229e1cae611649870e290f7e076da";
    hash = "sha256-6o0g9uVhuGYF9wbaSB91jjcYZioFLoEa+Yph+XfL2ZM=";
  };

  patches = [
    (fetchpatch {
      name = "flip-library-field-y.patch";
      url = "https://github.com/krishna-swaroop/ecad-viewer/commit/73c584a71b868ef9df8567493c2c634f415ad430.patch";
      hash = "sha256-lG+if2iianu0OnUa1Ca1cU4oyJXlcrmDfIQQT9wOT20=";
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
    runHook postInstall
  '';

  passthru.adapterCommit = finalAttrs.src.rev;

  meta = {
    description = "Standalone KiCad symbol and footprint renderer from ECAD Viewer";
    homepage = "https://github.com/krishna-swaroop/ecad-viewer";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
})
