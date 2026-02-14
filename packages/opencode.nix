# OpenCode CLI v1.1.64 — built from source.
#
# Based on the nixpkgs opencode package (v1.1.53) but updated to latest.
# Uses bun to compile a self-contained single-file executable.
#
# To update:
#   1. Bump `version`
#   2. Update `srcHash` (use `nix-prefetch-url --type sha256 --unpack` on the GitHub tarball)
#   3. Set `nodeModulesHash` to `lib.fakeHash`, build, and replace with the correct hash from the error
{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  makeBinaryWrapper,
  models-dev,
  ripgrep,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:
let
  version = "1.1.64";
  srcHash = "sha256-zCuJI8K11CAwC+IBejcUO3WtMs2p7L3vtHAUesInarM=";
  # Build node_modules once with lib.fakeHash to get the real hash, then paste it here.
  nodeModulesHash = "sha256-yza9eeMOWAd9ggGPMDs6ALjg7ptfk4iuN5y1rcUTIpc=";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  inherit version;

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    tag = "v${version}";
    hash = srcHash;
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      bun install \
        --cpu="*" \
        --frozen-lockfile \
        --filter ./packages/opencode \
        --filter ./packages/desktop \
        --ignore-scripts \
        --no-progress \
        --os="*"

      bun --bun ./nix/scripts/canonicalize-node-modules.ts
      bun --bun ./nix/scripts/normalize-bun-binaries.ts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = nodeModulesHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    installShellFiles
    makeBinaryWrapper
    models-dev
    writableTmpDirAsHomeHook
  ];

  postPatch = ''
    # Relax Bun version check to be a warning instead of an error
    # (nixpkgs ships bun 1.3.8, opencode v1.1.64 wants ^1.3.9)
    substituteInPlace packages/script/src/index.ts \
      --replace-fail 'throw new Error(`This script requires bun@''${expectedBunVersionRange}' \
                     'console.warn(`Warning: This script requires bun@''${expectedBunVersionRange}'
  '';

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .

    runHook postConfigure
  '';

  env.MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
  env.OPENCODE_VERSION = finalAttrs.version;
  env.OPENCODE_CHANNEL = "stable";

  buildPhase = ''
    runHook preBuild

    cd ./packages/opencode
    bun --bun ./script/build.ts --single --skip-install
    bun --bun ./script/schema.ts schema.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/opencode-*/bin/opencode $out/bin/opencode
    wrapProgram $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]}

    install -Dm644 schema.json $out/share/opencode/schema.json

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd opencode \
      --bash <($out/bin/opencode completion) \
      --zsh <(SHELL=/bin/zsh $out/bin/opencode completion)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  passthru = {
    jsonschema = "${placeholder "out"}/share/opencode/schema.json";
  };

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://opencode.ai/";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = [ "x86_64-linux" ];
  };
})
