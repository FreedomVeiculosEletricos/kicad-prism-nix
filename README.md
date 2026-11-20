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
  inputs.kicad-prism.url = "github:FreedomVeiculosEletricos/kicad-prism-nix/v5.3.0-alpha-nix.3";
}
```

Releases are named after the Prism release inside them. The `-nix.N` suffix
counts packaging fixes made without Prism itself changing. The newest one is on
the [releases page](https://github.com/FreedomVeiculosEletricos/kicad-prism-nix/releases/latest).

## What you get

```
packages.x86_64-linux.kicad-prism            the API server and its workers
                     .kicad-prism-frontend   the web UI and KiCad remote provider panel
                     .kicad-prism-viewer     the semantic viewer runtime
                     .ecad-renderer          ECAD Viewer's symbol, footprint and board renderer
                     .prism-kicad            the native KiCad parser and design-bundle CLI
                     .geometer               the geometry runtime prism-kicad launches

nixosModules.default   services.kicad-prism
overlays.default       all of the above, as a nixpkgs overlay
devShells.default      Python with Prism's dependencies, KiCad, Node.js and git
```

The NixOS module runs the API, a job worker and a component catalog worker as
hardened systemd units, serves the frontend through nginx and provisions a
local PostgreSQL database reached over its unix socket. The short version:

```nix
{
  services.kicad-prism = {
    enable = true;
    nginx.serverName = "prism.example.org";
    environmentFile = "/run/secrets/kicad-prism.env";
  };
}
```

Secrets such as `SESSION_SECRET` and `OIDC_CLIENT_SECRET` go in
`environmentFile`, never in `settings`, which ends up in the Nix store. To use
an external database, set `database.createLocally = false` and put the full
`PRISM_DATABASE_URL` in the same file.

### Trying a different version of Prism

Prism is a flake input here, so you can point it somewhere else without forking
anything:

```console
$ nix build --override-input kicad-prism github:krishna-swaroop/KiCAD-Prism/v5.3.0-alpha
$ nix build --override-input kicad-prism ../KiCAD-Prism
```

### One thing to leave alone

Don't make this flake's `nixpkgs` follow yours. Prism needs patched versions of
several Python packages, and a release means the whole set was built and tested
together. Pointing it at a different nixpkgs rebuilds all of it against
something nobody tried.

## How versions get here

Everything is built on [Garnix](https://garnix.io). It builds the flake's
checks, which cover every package and the dev shell.

Once a week we pull Prism's newest development code and push it to a `canary`
branch. If Garnix builds it, `main` moves forward; if it doesn't, `main` stays
where it was until someone looks.

Twice a day we check whether Prism has published a release. When they do, we
pin it on a `release/<tag>` branch and wait for Garnix. Only a green build gets
tagged here and published as a GitHub release.

So every release you can pin to has been built, and `main` never advances past
something broken.

## Maintenance

Packages are defined in `nix/overlay.nix`. Several of Prism's Python
dependencies are patched versions of what nixpkgs ships, which only an overlay
can express; the files under `nix/packages` re-export the result. Upstream
sources are selected in `nix/sources.nix`.

Version numbers are read out of `flake.lock` at evaluation time, so the pin and
the version can't drift apart.

`ecad-renderer` is built from the ECAD Viewer commit named in Prism's
`frontend/public/ecad-viewer.manifest.json`, so it follows whatever Prism pins.
The frontend refuses to build if the two disagree, swaps in the rebuilt bundles
and rewrites the manifest hashes and browser cache keys to match.

Both test suites run during the build: `npm test` for the frontend and pytest
for the backend. The backend tests that need a live PostgreSQL server are
deselected in `nix/packages/kicad-prism/package.nix`.

Fixes to Prism itself go in `upstreamPatches` in `nix/overlay.nix`. Drop each
one as soon as the pinned upstream carries it.

`nixpkgs` is only ever moved by hand, so that a failed weekly build can only
mean Prism changed:

```console
$ nix flake update nixpkgs
```
