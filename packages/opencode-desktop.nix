# OpenCode Desktop (Tauri) v1.1.64 — built from source.
#
# Based on the nixpkgs opencode-desktop package (v1.1.53) but updated to latest.
# Uses the opencode CLI package as a Tauri sidecar.
#
# To update: bump along with opencode.nix — this inherits version/src/node_modules
# from the CLI package. Only `cargoDepsHash` needs updating here (set to lib.fakeHash,
# build, and replace with the correct hash from the error).
{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  cargo-tauri,
  bun,
  nodejs,
  cargo,
  rustc,
  jq,
  wrapGAppsHook4,
  makeWrapper,
  dbus,
  glib,
  gtk3,
  libsoup_3,
  librsvg,
  libappindicator-gtk3,
  glib-networking,
  openssl,
  webkitgtk_4_1,
  callPackage,
  nix-prefetch-git,
  runCommandLocal,
}:
let
  opencode = callPackage ./opencode.nix { };

  # Workaround: nix-prefetch-git installs its binary with a versioned name
  # (e.g. "nix-prefetch-git-26.05...") but fetch-cargo-vendor-util expects
  # a plain "nix-prefetch-git" on PATH. Create a symlink with the right name.
  wrapPrefetchGit =
    pkg:
    runCommandLocal "nix-prefetch-git-wrapper"
      { passthru.override = args: wrapPrefetchGit (pkg.override args); }
      ''
        mkdir -p $out/bin
        for f in ${pkg}/bin/nix-prefetch-git*; do
          ln -s "$f" $out/bin/nix-prefetch-git
          break
        done
      '';

  fetchCargoVendor = rustPlatform.fetchCargoVendor.override {
    nix-prefetch-git = wrapPrefetchGit nix-prefetch-git;
  };

  cargoDepsHash = "sha256-Sfw/1380knqusED8OJcCn0D7erkX1sLtQq9m6Dd0v4Y=";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "opencode-desktop";
  inherit (opencode)
    version
    src
    node_modules
    ;

  patches = opencode.patches or [ ];

  cargoRoot = "packages/desktop/src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  # Provide pre-vendored cargo deps directly, using our fetchCargoVendor
  # override that fixes the nix-prefetch-git binary name.
  cargoDeps = fetchCargoVendor {
    inherit (opencode) src;
    name = "opencode-desktop-${opencode.version}";
    cargoRoot = "packages/desktop/src-tauri";
    hash = cargoDepsHash;
  };

  nativeBuildInputs = [
    pkg-config
    cargo-tauri.hook
    bun
    nodejs
    cargo
    rustc
    jq
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wrapGAppsHook4 ];

  buildInputs = lib.optionals stdenv.isLinux [
    dbus
    glib
    gtk3
    libsoup_3
    librsvg
    libappindicator-gtk3
    glib-networking
    openssl
    webkitgtk_4_1
  ];

  strictDeps = true;

  postPatch = ''
    # Relax Bun version check (same as CLI)
    substituteInPlace packages/script/src/index.ts \
      --replace-fail 'throw new Error(`This script requires bun@''${expectedBunVersionRange}' \
                     'console.warn(`Warning: This script requires bun@''${expectedBunVersionRange}'
  '';

  tauriBuildFlags = [
    "--config"
    "tauri.conf.json"
    "--config"
    "tauri.prod.conf.json"
    "--no-sign"
  ];

  preBuild = ''
    cp -a ${finalAttrs.node_modules}/{node_modules,packages} .
    chmod -R u+w node_modules packages
    patchShebangs node_modules
    patchShebangs packages/desktop/node_modules

    mkdir -p packages/desktop/src-tauri/sidecars
    cp ${opencode}/bin/opencode packages/desktop/src-tauri/sidecars/opencode-cli-${stdenv.hostPlatform.rust.rustcTarget}
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    mv $out/bin/OpenCode $out/bin/opencode-desktop
    sed -i 's|^Exec=OpenCode$|Exec=opencode-desktop|' $out/share/applications/OpenCode.desktop
  '';

  meta = {
    description = "AI coding agent desktop client";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    mainProgram = "opencode-desktop";
    platforms = [ "x86_64-linux" ];
  };
})
