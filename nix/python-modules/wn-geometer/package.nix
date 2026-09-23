{
  lib,
  autoPatchelfHook,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,
  stdenv,
}:

let
  wheels = {
    x86_64-linux = {
      platform = "manylinux_2_35_x86_64";
      hash = "sha256-SvfDcoTbrH5ewm1+QlF8zYQWkn75s0thYqP3sDAMesg=";
    };
    aarch64-linux = {
      platform = "manylinux_2_35_aarch64";
      hash = "sha256-OQBK+C7ZoaN27SrBIWxjGhCIyaR8QFYuwHWOfYwoj1I=";
    };
    aarch64-darwin = {
      platform = "macosx_11_0_arm64";
      hash = "sha256-84i8DqzxB69I2OS/LaNIKC+iQFJO/gABttZlouSXWr8=";
    };
  };
  wheel =
    wheels.${stdenv.hostPlatform.system}
      or (throw "wn-geometer: no wheel for ${stdenv.hostPlatform.system}");
in
buildPythonPackage {
  pname = "wn-geometer";
  version = "2026.9.7";
  format = "wheel";

  disabled = pythonOlder "3.10";

  src = fetchPypi {
    pname = "wn_geometer";
    version = "2026.9.7";
    inherit (wheel) hash platform;
    format = "wheel";
    dist = "py3";
    python = "py3";
    abi = "none";
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  pythonImportsCheck = [ "geometer" ];

  meta = {
    description = "Python bindings for Geometer CAD geometry operations";
    homepage = "https://github.com/wavenumber-eng/geometer";
    changelog = "https://github.com/wavenumber-eng/geometer/blob/v2026-09-07/CHANGELOG.md";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "geometer";
    platforms = lib.attrNames wheels;
  };
}
