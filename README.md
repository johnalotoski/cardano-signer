# cardano-signer (Nix Flake)

This project packages the `cardano-signer` Node.js CLI using Nix and Yarn from
the excellent upstream repo:
[cardano-signer](https://github.com/gitmachtl/cardano-signer).

---

## Building with Nix

To build the cardano-signer:

    nix build -L .#cardano-signer

The CLI binary will be available to run at:

    ./result/bin/cardano-signer "${ARGS[@]}"

---

## Running remotely

To run the CLI tool from this flake without cloning:

    nix run github:johnalotoski/cardano-signer -- "${ARGS[@]}"

You can also run from a local flake path:

    nix run .#cardano-signer -- "${ARGS[@]}"

---

## Development Shell

To enter a dev environment with `node`, `yarn`, and helper tools:

    nix develop

or, if you have [direnv](https://direnv.net) installed:

    direnv allow

---

## Updating the cardano-signer version

* Update the commit found at `srcRepo.rev` in `flake.nix` and save
* Reload the devShell to preload the new source repo
* Run `update-yarn-file` to generate a new `yarn-$SHORT_REV.lock`
* Make sure the build succeeds with:

    nix build -L .#cardano-signer

* Remove the old `yarn-$OLD_SHORT_REV.lock` file
* Commit the changes
* Celebrate! :)

---

## Directory layout after build

    result/
    ├── bin/
    │   └── cardano-signer
    └── libexec/cardano-signer/
        ├── deps/
        │   └── cardano-signer/
        ├── node_modules/
        └── ...
