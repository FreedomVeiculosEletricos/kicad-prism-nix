{
  lib,
  coreutils,
  geometer,
  git,
  git-lfs,
  gnutar,
  kicad,
  kicad-prism-frontend,
  makeWrapper,
  nodejs,
  openssh,
  prism-kicad,
  pyproject-nix,
  python3,
  python312Packages,
  sources,
  upstreamPatches,
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

  testDependencies = with python312Packages; [
    httpx
    jsonschema
    pytest
    pytest-xdist
  ];

  kicadPython = python3.buildEnv.override {
    extraLibs = with python3.pkgs; [
      requests
      six
      wxpython
    ];
    postBuild = ''
      echo ${kicad.base}/${python3.sitePackages} > $out/${python3.sitePackages}/kicad.pth
    '';
  };

  toolchainPath = lib.makeBinPath [
    coreutils
    git
    git-lfs
    gnutar
    kicad
    nodejs
    openssh
    prism-kicad
    python
  ];

  installCheckScript = writeText "kicad-prism-install-check.py" ''
    import shutil

    import app.main

    print(app.main.app.title)

    for tool in ("kicad-cli", "prism-kicad", "git-lfs"):
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
  patches = upstreamPatches;
  nativeBuildInputs = [ makeWrapper ];
  inherit dependencies;
  dontWrapPythonPrograms = true;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/${python.sitePackages}/app/static
    cp -r backend/app/. $out/${python.sitePackages}/app

    cp -r ${kicad-prism-frontend}/share/kicad-prism/remote-provider \
      $out/${python.sitePackages}/app/static/remote_provider

    local -a wrapperArgs=(
      --prefix PATH : ${toolchainPath}
      --prefix PYTHONPATH : "$out/${python.sitePackages}:${makePythonPath dependencies}"
      --set-default PRISM_DESIGN_BUNDLE_CLI_PATH ${lib.getExe prism-kicad}
      --set-default PRISM_DESIGN_BUNDLE_SCHEMA_DIR ${prism-kicad}/share/prism-kicad/schema
      --set-default PRISM_ARTWORK_CONFIG_DIR ${prism-kicad}/share/prism-kicad/artwork-configs
      --set-default GEOMETER_EXECUTABLE ${lib.getExe geometer}
      --set-default PRISM_KICAD_PYTHON ${kicadPython.interpreter}
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

    HOME=$TMPDIR ${kicadPython.interpreter} -I -c "import pcbnew; pcbnew.ZONE_FILLER(pcbnew.BOARD())"

    PATH=${toolchainPath} \
    PYTHONPATH="$out/${python.sitePackages}:${makePythonPath dependencies}" \
    AUTH_ENABLED=false \
      ${python.interpreter} ${installCheckScript} > /dev/null

    (
      cd backend
      PATH=${toolchainPath} \
      PYTHONPATH="${makePythonPath (dependencies ++ testDependencies)}" \
      AUTH_ENABLED=false \
        ${python.interpreter} -m pytest -p no:cacheprovider -q \
          --deselect tests/test_job_outcomes.py::ReleaseBuildRowFencingTests \
          --deselect tests/test_token_issuer_scopes.py::ServiceClientTokenTests
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
