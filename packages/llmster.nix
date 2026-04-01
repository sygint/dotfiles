# llmster — LM Studio headless daemon (standalone, no GUI)
#
# Downloads the official llmster tarball which bundles:
#   - llmster bootstrap binary (Node.js SEA)
#   - lms CLI (Node.js SEA)
#   - node, deno runtimes
#   - llama.cpp backends (CPU, Vulkan, CUDA 12)
#   - bundled plugins (RAG, code sandbox)
#
# Uses buildFHSEnv because the binaries are Node.js Single Executable
# Applications (SEA) that break when autoPatchelfHook modifies their RPATH.
#
# At service start, `llmster bootstrap` copies itself into ~/.lmstudio/
# and `lms daemon up` starts the inference daemon.
#
# To update:
#   1. Check: curl -fsSL https://lmstudio.ai/install.sh | head -30
#   2. Bump `version` to match APP_VERSION
#   3. Set `hash` to `lib.fakeHash`, build, replace with correct hash
{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  gcc,
  cudaPackages,
  addDriverRunpath,
  writeShellScript,
}:
let
  pname = "llmster";
  version = "0.0.8-1";

  src = fetchurl {
    url = "https://llmster.lmstudio.ai/download/${version}-linux-x64.full+cuda12.tar.gz";
    hash = "sha256-jvoC41SFEKOFtHdx8xxlbpPiJ1UFWvyGiSedxfeQXPk=";
  };

  # Unpack the tarball into a fixed derivation
  llmster-unpacked = stdenv.mkDerivation {
    pname = "${pname}-unpacked";
    inherit version src;

    sourceRoot = ".";
    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      mkdir -p $out
      cp -r llmster .bundle $out/
      chmod -R u+w $out
    '';
  };

  # Common FHS target packages — shared libs needed by llmster and its
  # bundled llama.cpp backends
  targetPkgs = pkgs: [
    pkgs.stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
    pkgs.glibc            # libc, libm, libdl, libpthread
    gcc.cc.lib            # libatomic.so.1, libgomp.so.1
    cudaPackages.cuda_cudart    # libcudart.so.12
    cudaPackages.libcublas.lib  # libcublas.so.12
  ];

  # FHS wrapper for the lms CLI
  lms-fhs = buildFHSEnv {
    name = "lms";
    inherit targetPkgs;
    extraBwrapArgs = [
      "--bind" "${llmster-unpacked}" "${llmster-unpacked}"
    ];
    runScript = writeShellScript "lms-run" ''
      # If lms has been bootstrapped, use the installed version.
      # Otherwise fall back to the bundled one.
      if [ -x "$HOME/.lmstudio/bin/lms" ]; then
        exec "$HOME/.lmstudio/bin/lms" "$@"
      else
        exec "${llmster-unpacked}/.bundle/lms" "$@"
      fi
    '';
  };

  # FHS wrapper for the llmster daemon/bootstrap binary
  llmster-fhs = buildFHSEnv {
    name = "llmster";
    inherit targetPkgs;
    extraBwrapArgs = [
      "--bind" "${llmster-unpacked}" "${llmster-unpacked}"
    ];
    runScript = writeShellScript "llmster-run" ''
      exec "${llmster-unpacked}/llmster" "$@"
    '';
  };
in
stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin

    # Symlink the FHS-wrapped binaries
    ln -s ${lms-fhs}/bin/lms $out/bin/lms
    ln -s ${llmster-fhs}/bin/llmster $out/bin/llmster

    # Also expose the unpacked bundle for systemd service reference
    ln -s ${llmster-unpacked} $out/lib
  '';

  passthru = {
    unpacked = llmster-unpacked;
  };

  meta = {
    description = "LM Studio headless daemon — local AI inference server";
    homepage = "https://lmstudio.ai/";
    license = lib.licenses.unfree;
    mainProgram = "lms";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
