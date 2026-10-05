{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  lib,
  username,
  ...
}:

{
  # ── Kernel ─────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # ── Nix ────────────────────────────────
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];

    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── nix-ld（実用フルセット）────────────
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # toolchain runtime
      stdenv.cc.cc

      # core
      glfw
      openal
      zlib
      openssl
      curl
      expat
      icu
      nss

      # graphics
      wayland
      wayland-protocols
      libxkbcommon
      libGL
      vulkan-loader

      # audio / device
      alsa-lib
      udev
      

      # frequently required
      dbus
      freetype
      libpng
    ];
  };

  # ── pkg-config を通す ─────────────────
  environment.sessionVariables = {
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" [
      pkgs.fontconfig.dev
      pkgs.systemd.dev
      pkgs.wayland.dev
      pkgs.libxkbcommon.dev
      pkgs.alsa-lib.dev
      pkgs.openssl.dev
      pkgs.zlib.dev
      pkgs.libpng.dev
      pkgs.freetype.dev
      pkgs.udev.dev
      pkgs.dbus.dev
      pkgs.wayland-protocols
      pkgs.libGL.dev

    ];
    LD_LIBRARY_PATH = lib.makeLibraryPath (
      with pkgs;
      [
        wayland
        libxkbcommon
        vulkan-loader
        libGL
        alsa-lib
        pipewire.jack
        udev
      ]
    );
  };


  # ── Kanata ────────────────────────────
  services.kanata = {
    enable = true;
    package = pkgs-stable.kanata;
    keyboards.default = {
      config = ''
        (defsrc
          caps
        )

        (deflayer default
         lctl
        )
      '';
    };
  };
  i18n.supportedLocales = [
  "en_US.UTF-8/UTF-8"
  "ja_JP.UTF-8/UTF-8"
];


  users.groups.uinput = { };

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  # ── IME ───────────────────────────────
  services.hazkey = {
    enable = true;
    zenzai.package = inputs.nix-hazkey.packages.${pkgs.stdenv.hostPlatform.system}.zenzai_v3_1-small;
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };

  # ── Locale ────────────────────────────
  time.timeZone = "Asia/Tokyo";

  # ── 1Password ─────────────────────────
  programs._1password.enable = true;

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };

  # ── SSH ───────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  # ── Network ───────────────────────────
  networking.networkmanager.enable = true;

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.sauce-code-pro
      moralerspace # ← nf版に変更
      udev-gothic-nf
      nerd-fonts.hack
      hackgen-nf-font
      plemoljp-nf
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      # ← まとめて1つに
      defaultFonts = {
        monospace = [
          "UDEV Gothic 35NF"
          "Noto Sans Mono CJK JP"
        ];
        sansSerif = [ "Noto Sans CJK JP" ];
        serif = [ "Noto Serif CJK JP" ];
      };
      hinting = {
        enable = true;
        style = "slight";
      };
      antialias = true;
      subpixel.rgba = "rgb";
    };
  };
  # ── Polkit / Keyring ──────────────────
  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;

  # ── XKB ───────────────────────────────
  services.xserver = {
    xkb.layout = "jp";
  };

  environment.systemPackages = with pkgs; [
    # ── build system
    pkg-config
    cmake
    ninja
    meson
    gnumake
    binutils

    # ── core
    glibc
    glibc.dev
    zlib
    zlib.dev
    openssl
    openssl.dev
    libffi
    expat
    ncurses

    # ── Linux基盤
    udev
    udev.dev
    dbus

    # ── X11（かなり重要）
    libx11
    libxcursor
    libxi
    libxrandr
    libxrender
    libxext
    libxfixes
    libxinerama

    # ── Wayland
    wayland
    wayland.dev
    wayland-protocols
    libxkbcommon
    libxkbcommon.dev

    # ── GPU
    libGL
    vulkan-loader
    vulkan-headers

    # ── audio
    alsa-lib
    alsa-lib.dev
    pulseaudio

    # ── image/font
    freetype
    freetype.dev
    libpng
    libpng.dev
    libjpeg
    fontconfig

    # ── compression
    xz
    bzip2
  ];
}
