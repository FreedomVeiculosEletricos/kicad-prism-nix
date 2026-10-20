{
  lib,
  buildPythonPackage,
  cython,
  eigen,
  fcl,
  fetchFromGitHub,
  numpy,
  octomap,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage rec {
  pname = "python-fcl";
  version = "0.7.0.11";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "BerkeleyAutomation";
    repo = "python-fcl";
    tag = "v${version}";
    hash = "sha256-xJnVA2aOQ8HHD+see1HtvUgo2mcILrfN/GT3MhyNDNk=";
  };

  build-system = [
    cython
    numpy
    setuptools
  ];

  buildInputs = [
    eigen
    fcl
    octomap
  ];

  env.NIX_CFLAGS_COMPILE = "-I${eigen}/include/eigen3";

  dependencies = [
    cython
    numpy
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  disabledTests = [ "signed_distance" ];

  preCheck = ''
    rm -rf src
  '';

  pythonImportsCheck = [ "fcl" ];

  meta = {
    description = "Python bindings for the Flexible Collision Library";
    homepage = "https://github.com/BerkeleyAutomation/python-fcl";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ ];
  };
}
