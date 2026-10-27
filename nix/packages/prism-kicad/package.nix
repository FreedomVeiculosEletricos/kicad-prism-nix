{
  lib,
  git,
  rustPlatform,
  sources,
}:

rustPlatform.buildRustPackage {
  pname = "prism-kicad";
  version = sources.version;

  src = sources.kicad-prism;

  cargoRoot = "native";
  buildAndTestSubdir = "native";
  cargoLock.lockFile = sources.native + "/Cargo.lock";

  cargoBuildFlags = [
    "--package"
    "prism-kicad-cli"
  ];
  cargoTestFlags = [
    "--package"
    "prism-kicad-cli"
  ];

  nativeCheckInputs = [ git ];

  postInstall = ''
    mkdir -p $out/share/prism-kicad
    cp -r native/contracts/generated/schema $out/share/prism-kicad/schema
    cp -r native/src/rs/prism-artwork/configs $out/share/prism-kicad/artwork-configs
  '';

  meta = {
    description = "KiCad parser and design-bundle CLI behind KiCad Prism";
    homepage = "https://github.com/krishna-swaroop/KiCAD-Prism";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "prism-kicad";
    platforms = lib.platforms.unix;
  };
}
