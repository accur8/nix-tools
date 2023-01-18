#!/usr/bin/env bash

set -euo pipefail

# Always run the script from the project root
cd "$(dirname "$0")/.."

#echo "Generating SBT Nix deps..."
#sbt run # select a8.versions.GenerateSbtDotNix

echo "Generating classpath derivation for exported JARs..."
#nix-build --out-link lib -E 'with import <nixpkgs> {}; (callPackage ./nix/classpath-builder {}) {jars = (import ./sbt-deps.nix); }'
nix-build --out-link samples/apps/boomboom -E 'with import <nixpkgs> {}; (callPackage ./javaLauncher {}) { name = "boomboom"; mainClass = "a8.versions.apps.Main"; jvmArgs = ["-Xmx4g"]; sbtDependenciesFn = import ./samples/sbt-deps.nix; }'

echo "Done!"
