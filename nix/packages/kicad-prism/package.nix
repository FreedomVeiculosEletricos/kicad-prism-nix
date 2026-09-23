{
  lib,
  coreutils,
  git,
  gnutar,
  kicad,
  kicad-prism-frontend,
  kicad-prism-viewer,
  makeWrapper,
  nodejs,
  openssh,
  prism-clipper2,
  pyproject-nix,
  python312Packages,
  sources,
  writeText,
}:

let
  inherit (python312Packages) makePythonPath python;

  upstream = pyproject-nix.lib.project.loadRequirementsTxt {
    requirements = builtins.readFile sources.requirements;
    projectRoot = sources.kicad-prism;
  };

  acceptedDrift = {
    bcrypt = "nixpkgs ships 5.0.0; upstream's <5 cap guards a path this app closes itself";
  };

  drift = upstream.validators.validateVersionConstraints { inherit python; };

  unexpectedDrift = lib.attrNames (lib.removeAttrs drift (lib.attrNames acceptedDrift));

  dependencies = lib.throwIf (unexpectedDrift != [ ]) ''
    kicad-prism: nixpkgs does not satisfy what upstream declares for ${lib.concatStringsSep ", " unexpectedDrift}.
    Override the package, hold the bump, or record the mismatch in `acceptedDrift` with the reason it is safe.
  '' (upstream.renderers.buildPythonPackage { inherit python; }).dependencies;

  viewerRoot = "${kicad-prism-viewer}/share/kicad-prism-viewer";

  toolchainPath = lib.makeBinPath [
    coreutils
    git
    gnutar
    kicad
    nodejs
    openssh
    python
    python312Packages.kicad-cruncher
  ];

  installCheckScript = writeText "kicad-prism-install-check.py" ''
    import shutil

    import app.main

    print(app.main.app.title)

    for tool in ("kicad-cli", "kicad-cruncher"):
        found = shutil.which(tool)
        if found is None:
            raise SystemExit(f"{tool} is not on PATH; the wrapper did not take")
        print(found)
  '';
in
python312Packages.buildPythonApplication {
  pname = "kicad-prism";
  version = sources.version;
  pyproject = false;
  src = sources.kicad-prism;
  nativeBuildInputs = [ makeWrapper ];
  inherit dependencies;
  dontWrapPythonPrograms = true;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/${python.sitePackages}/app/static
    cp -r backend/app/. $out/${python.sitePackages}/app

    install -Dm444 -t $out/${python.sitePackages}/scripts \
      scripts/ecad-diff.mjs scripts/ecad-parse.mjs
    cp -r scripts/vendor $out/${python.sitePackages}/scripts/vendor

    cp -r ${kicad-prism-frontend}/share/kicad-prism/remote-provider \
      $out/${python.sitePackages}/app/static/remote_provider

    local -a wrapperArgs=(
      --prefix PATH : ${toolchainPath}
      --prefix PYTHONPATH : "$out/${python.sitePackages}:${makePythonPath dependencies}"
      --set-default PRISM_SEMANTIC_VIEWER_REPO ${viewerRoot}
      --set-default PRISM_CLIPPER2_LIBRARY ${prism-clipper2}/lib/libprism_clipper2.so
    )

    makeWrapper ${python.interpreter} $out/bin/kicad-prism-server \
      --add-flags "-m uvicorn app.main:app" "''${wrapperArgs[@]}"
    makeWrapper ${python.interpreter} $out/bin/kicad-prism-worker \
      --add-flags "-m app.prism_worker" "''${wrapperArgs[@]}"

    runHook postInstall
  '';
  doInstallCheck = true;
  preInstallCheck = ''
    # Binds a loopback socket, which the sandbox has none of. -f because
    # upstream releases older than the test itself do not carry the file.
    rm -f backend/tests/test_gzip_middleware.py
  '';
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/kicad-prism-worker --help > /dev/null

    PATH=${toolchainPath} \
    PYTHONPATH="$out/${python.sitePackages}:${makePythonPath dependencies}" \
    AUTH_ENABLED=false \
      ${python.interpreter} ${installCheckScript} > /dev/null

    (
      cd backend
      PATH=${toolchainPath} \
      PYTHONPATH="${makePythonPath dependencies}" \
      AUTH_ENABLED=false \
        ${python.interpreter} -m unittest discover -s tests -p "test_*.py"
    )

    runHook postInstallCheck
  '';
  passthru = {
    frontend = kicad-prism-frontend;
    kicad = kicad;
  };
  meta = {
    description = "Self-hosted PCB review and component governance platform for KiCad";
    homepage = "https://github.com/krishna-swaroop/KiCAD-Prism";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "kicad-prism-server";
    platforms = lib.platforms.linux;
  };
}
