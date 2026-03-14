# LM Studio 0.4.6-1 — updated from nixpkgs (which ships 0.4.5-2).
#
# Self-contained AppImage wrapper. Based on the nixpkgs lmstudio package
# (pkgs/by-name/lm/lmstudio/).
#
# The desktop entry uses mullvad-exclude so LM Link's embedded Tailscale
# mesh VPN can reach its control plane without being blocked by Mullvad.
#
# To update:
#   1. Check latest: curl -ILs -o /dev/null -w '%{url_effective}' https://lmstudio.ai/download/latest/linux/x64
#   2. Bump `version` to the version from the URL
#   3. Set `hash` to `lib.fakeHash`, build, and replace with the correct hash from the error
{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
  graphicsmagick,
}:
let
  pname = "lmstudio";
  version = "0.4.6-1";
  hash = "sha256-FHZ64zmnqHrQyX4ift/lVUzW+HiCVkXpWVa4hkssX/k=";

  src = fetchurl {
    url = "https://installers.lmstudio.ai/linux/x64/${version}/LM-Studio-${version}-x64.AppImage";
    inherit hash;
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ graphicsmagick ];

  extraPkgs = pkgs: [ pkgs.ocl-icd ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications

    # Generate icons at standard sizes from the upstream 0x0 source icon
    src_icon="${appimageContents}/usr/share/icons/hicolor/0x0/apps/lm-studio.png"
    sizes=("16x16" "32x32" "48x48" "64x64" "128x128" "256x256")
    for size in "''${sizes[@]}"; do
      install -dm755 "$out/share/icons/hicolor/$size/apps"
      gm convert "$src_icon" -resize "$size" "$out/share/icons/hicolor/$size/apps/lm-studio.png"
    done

    install -m 444 -D ${appimageContents}/lm-studio.desktop -t $out/share/applications

    # Rename the main executable from lmstudio to lm-studio
    mv $out/bin/lmstudio $out/bin/lm-studio

    substituteInPlace $out/share/applications/lm-studio.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=mullvad-exclude lm-studio'

    # lms cli tool
    install -m 755 ${appimageContents}/resources/app/.webpack/lms $out/bin/

    patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" \
      --set-rpath "${lib.getLib stdenv.cc.cc}/lib:${lib.getLib stdenv.cc.cc}/lib64:$out/lib:${
        lib.makeLibraryPath [ (lib.getLib stdenv.cc.cc) ]
      }" $out/bin/lms
  '';

  meta = {
    description = "LM Studio is an easy to use desktop app for experimenting with local and open-source Large Language Models (LLMs)";
    homepage = "https://lmstudio.ai/";
    license = lib.licenses.unfree;
    mainProgram = "lm-studio";
    maintainers = with lib.maintainers; [ crertel ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
