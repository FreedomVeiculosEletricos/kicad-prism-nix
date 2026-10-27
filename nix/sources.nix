# Plain subpath selection rather than lib.fileset: fileset refuses store paths,
# and the input is pinned by revision anyway, so everything rebuilds together.
{
  lib,
  lastModifiedDate,
  ref,
  src,
}:
let
  release = lib.hasPrefix "v" ref;

  day = builtins.substring 0 8 lastModifiedDate;

  version =
    if release then
      lib.removePrefix "v" ref
    else
      "0-unstable-${builtins.substring 0 4 day}-${builtins.substring 4 2 day}-${builtins.substring 6 2 day}";
in
{
  inherit release version;

  requirements = src + "/requirements/runtime.in";

  kicad-prism = src;
  kicad-prism-frontend = src + "/frontend";
  kicad-prism-viewer = src + "/kicad-prism-viewer";
  native = src + "/native";
}
