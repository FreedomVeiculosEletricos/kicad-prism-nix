{
  lib,
  autoPatchelfHook,
  fetchurl,
  stdenv,
  unzip,
}:

let
  assets = {
    x86_64-linux = {
      name = "native-linux-x64.zip";
      hash = "sha256-XXvraCMlTHVFg/EiK1TCeL0R/41HGByaBGK27SBc3cc=";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system}
      or (throw "geometer: no runtime for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "geometer";
  version = "2026-09-19";

  src = fetchurl {
    url = "https://github.com/wavenumber-eng/geometer/releases/download/v${finalAttrs.version}/${asset.name}";
    inherit (asset) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    install -Dm555 geometer -t $out/bin
    install -Dm444 licenses/* -t $out/share/licenses/geometer

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/geometer --version | grep -q 'abi 20260919'
    runHook postInstallCheck
  '';

  meta = {
    description = "Geometer runtime that prism-kicad launches for assembly hidden-line removal";
    homepage = "https://github.com/wavenumber-eng/geometer";
    license = with lib.licenses; [
      mit
      lgpl21Only
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "geometer";
    platforms = lib.attrNames assets;
  };
})
