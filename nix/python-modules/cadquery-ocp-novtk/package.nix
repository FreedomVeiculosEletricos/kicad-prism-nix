{
  lib,
  autoPatchelfHook,
  buildPythonPackage,
  cadquery-ocp-proxy,
  expat,
  fetchPypi,
  libGL,
  libX11,
  python,
  stdenv,
  zlib,
}:

let
  wheels = {
    x86_64-linux = {
      platform = "manylinux_2_31_x86_64";
      hash = "sha256-YEl89CQZ3SAA0yOrdyk39hU58vCl0+8bKIYRsTJUxYc=";
    };
    aarch64-linux = {
      platform = "manylinux_2_31_aarch64";
      hash = "sha256-hHzngznOKGDyWj0xCYUsnHdG9EUCk/NZ9p7KpXlndS8=";
    };
  };

  wheel =
    wheels.${stdenv.hostPlatform.system}
      or (throw "cadquery-ocp-novtk: no wheel for ${stdenv.hostPlatform.system}");

  pyTag = "cp${lib.replaceStrings [ "." ] [ "" ] python.pythonVersion}";
in
buildPythonPackage rec {
  pname = "cadquery-ocp-novtk";
  version = "7.9.3.1.1";
  format = "wheel";

  src = fetchPypi {
    pname = "cadquery_ocp_novtk";
    inherit format version;
    inherit (wheel) hash platform;
    dist = pyTag;
    python = pyTag;
    abi = pyTag;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    expat
    libGL
    libX11
    stdenv.cc.cc.lib
    zlib
  ];

  dependencies = [ cadquery-ocp-proxy ];

  pythonImportsCheck = [
    "OCP"
    "OCP.gp"
    "OCP.STEPCAFControl"
  ];

  meta = {
    description = "OCCT Python bindings built without VTK";
    homepage = "https://github.com/CadQuery/OCP";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ ];
    platforms = lib.attrNames wheels;
  };
}
