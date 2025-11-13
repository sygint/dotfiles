#!/usr/bin/env bash
# Optimized Brave Browser Launcher
# Performance and Wayland optimization flags based on Arch Wiki Chromium recommendations
# Reference: https://wiki.archlinux.org/title/Chromium

exec brave \
  --ozone-platform=wayland \
  --enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks \
  --disable-features=UseChromeOSDirectVideoDecoder \
  --enable-gpu-rasterization \
  --enable-zero-copy \
  --ignore-gpu-blocklist \
  --process-per-site \
  "$@"
