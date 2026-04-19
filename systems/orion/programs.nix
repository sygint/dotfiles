{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./homes/syg.nix
  ];

  home.packages = with pkgs; [
    # CLI Applications
    fastfetch
    rofi
    tealdeer
    tree
    usbutils
    yazi
    zellij

    # Desktop Applications
    element-desktop
    ghostty
    gimp
    gnome-calculator
    gparted
    inkscape
    keepassxc
    kitty
    libreoffice
    librewolf-unwrapped
    meld
    nemo-with-extensions
    obsidian
    rocketchat-desktop
    shiori
    signal-desktop
    solaar
    zed-editor
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Qt theming support
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    adwaita-qt
    adwaita-qt6

    # Development Tools
    act
    gh
    direnv
    lazygit
    opencode
  ];
}
