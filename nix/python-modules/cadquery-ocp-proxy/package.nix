{
  lib,
  buildPythonPackage,
  fetchPypi,
}:

buildPythonPackage rec {
  pname = "cadquery-ocp-proxy";
  version = "7.9.3.1.1";
  format = "wheel";

  src = fetchPypi {
    pname = "cadquery_ocp_proxy";
    inherit format version;
    dist = "py3";
    python = "py3";
    hash = "sha256-ykFk7EtUlW2fw+aMZ9VVtUhsuWPC9x4Y3wBboWuSHJE=";
  };

  pythonImportsCheck = [ "cadquery_ocp_proxy" ];

  meta = {
    description = "Proxy package to track the cadquery-ocp and cadquery-ocp-novtk version";
    homepage = "https://github.com/CadQuery/ocp-build-system";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
  };
}
