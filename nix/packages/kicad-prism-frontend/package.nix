{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  importNpmLock,
  kicad-prism-viewer,
  sources,
}:

let
  # PR #683 rebuilds the release viewer with only the KiCad 10 sheet-path fix.
  viewerBackport = fetchFromGitHub {
    owner = "krishna-swaroop";
    repo = "KiCAD-Prism";
    rev = "1c8fc737fda77c94cde7114855aca31859892c68";
    hash = "sha256-/XSi9Okcrw0L+cEwU5MCiozXhUWtD9Oq0eqD1tILQ3s=";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "kicad-prism-frontend";
  version = sources.version;

  src = sources.kicad-prism-frontend;

  # PR #682, backported to the viewer host in our pinned upstream revision.
  patches = [ ../../patches/682-load-project-and-page-layout.patch ];

  postPatch = ''
    # Refuse to combine the release bundle with a different worker/renderer.
    cmp public/parser.worker.js ${viewerBackport}/frontend/public/parser.worker.js
    cmp public/ecad-renderer.js ${viewerBackport}/frontend/public/ecad-renderer.js
    cp ${viewerBackport}/frontend/public/ecad-viewer{.js,.manifest.json} public/
    substituteInPlace index.html \
      --replace-fail \
        'ecad-viewer.js?v=55ef0a844038a87f30e968b9509cafd4c6e25414ec0ca3700a296529f3f8939a' \
        'ecad-viewer.js?v=a980a27be70e1922ecd22c1754e803f64093f1d5cae26b5b5c89b77f56b9ba73'
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
    node ${../../checks/ecad-viewer-artifacts.mjs}
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
