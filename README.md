# kicad-prism-nix

Run [KiCad Prism](https://github.com/krishna-swaroop/KiCAD-Prism) on NixOS.

Prism doesn't ship Nix files of its own, so they live here. There's no copy of
their code in this repo — it points at theirs and builds it.

## Use it

```nix
{
  inputs.kicad-prism.url = "github:FreedomVeiculosEletricos/kicad-prism-nix";
}
```

That default follows Prism's development branch, but never blindly: it only
moves to a commit we've actually built. It's a reasonable thing to track if you
want new features early.

For a server, pin a release instead:

```nix
{
  inputs.kicad-prism.url = "github:FreedomVeiculosEletricos/kicad-prism-nix/v3.0.2-alpha-nix.1";
}
```

Releases are named after the Prism release inside them. The `-nix.1` counts
packaging fixes made without Prism itself changing.

## What you get

```
packages.x86_64-linux.kicad-prism            the server and worker
                     .kicad-prism-frontend   the web UI and KiCad panel
                     .kicad-prism-viewer      the semantic viewer runtime
                     .prism-clipper2          its native geometry library

nixosModules.default   services.kicad-prism
overlays.default       all of the above, as a nixpkgs overlay
devShells              a shell with Prism's dependencies, KiCad and node
```

The NixOS module runs the server behind nginx with a systemd worker, a
PostgreSQL database and a hardened unit. `services.kicad-prism.enable = true`
and a `nginx.serverName` is the short version.

### Trying a different version of Prism

Prism is a flake input here, so you can point it somewhere else without forking
anything:

```console
$ nix build --override-input kicad-prism github:krishna-swaroop/KiCAD-Prism/v3.1.0-alpha
$ nix build --override-input kicad-prism ../KiCAD-Prism
```

### One thing to leave alone

Don't make this flake's `nixpkgs` follow yours. Prism needs patched versions of
several Python packages, and a release means the whole set was built and tested
together. Pointing it at a different nixpkgs rebuilds all of it against
something nobody tried.

## How versions get here

Once a week we pull Prism's newest development code and build it. If it builds,
this repo moves forward; if it doesn't, it stays where it was until someone
looks.

Twice a day we check whether Prism has published a release. When they do, we
tag it here and build the tag; a GitHub release is published only if it's
green. A tag without a release is one that failed.

So every release you can pin to has been built at least once, and the branch
never advances past something broken.

## Maintenance

Packages are defined in `nix/overlay.nix`. Several of Prism's Python
dependencies are patched versions of what nixpkgs ships, which only an overlay
can express; the files under `nix/packages` re-export the result.

Version numbers are read out of `flake.lock` at evaluation time, so the pin and
the version can't drift apart.

Application fixes are kept in `nix/patches` and applied by the affected package.
The frontend carries a backport of [upstream PR #682](https://github.com/krishna-swaroop/KiCAD-Prism/pull/682)
to load project settings, custom page layouts and subsheets with the root sheet.
Its regression tests run during the Nix build. Remove the backport when the
pinned upstream includes the fix; check patch compatibility before changing the
upstream input.

The frontend also uses the viewer bundle and manifest from [upstream PR #683,
commit `1c8fc737`](https://github.com/krishna-swaroop/KiCAD-Prism/pull/683/commits/1c8fc737fda77c94cde7114855aca31859892c68).
This fixes KiCad 10 variant DNP marks when the project's top-level sheet UUID
differs from the schematic UUID. The parser worker and library renderer stay
byte-identical to the release. The build rejects incompatible assets, verifies
the manifest hashes and browser cache key, and runs the full frontend test suite.
Remove both backports when the pinned upstream includes the complete fixes.

`nixpkgs` is only ever moved by hand, so that a failed weekly build can only
mean Prism changed:

```console
$ nix flake update nixpkgs
```
