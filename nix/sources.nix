# Plain subpath selection rather than lib.fileset: fileset refuses store paths,
# and the input is pinned by revision anyway, so everything rebuilds together.
{
  lib,
  src,
  ref,
  lastModifiedDate,
}:
let
  day = builtins.substring 0 8 lastModifiedDate;

  version =
    if lib.hasPrefix "v" ref then
      lib.removePrefix "v" ref
    else
      "0-unstable-${builtins.substring 0 4 day}-${builtins.substring 4 2 day}-${builtins.substring 6 2 day}";
in
{
  inherit version;

  requirements =
    if builtins.pathExists (src + "/requirements/runtime.in") then
      src + "/requirements/runtime.in"
    else
      src + "/backend/requirements.txt";

  kicad-prism = src;
  kicad-prism-frontend = src + "/frontend";
  kicad-prism-viewer = src + "/kicad-prism-viewer";
  prism-clipper2 = src + "/kicad-prism-viewer/native/prism-clipper2";
}
