{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./zerotier-configuration.nix
  ];

  ########################################
  # Nix
  ########################################
  system.stateVersion = "20.09";
  nix.autoOptimiseStore = true;
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {

      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      gnupg = pkgs.gnupg.override { libusb1 = pkgs.libusb1; };

      # Allow unstable.PackageName
      unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
    };
  };

  # Include current config:
  environment.etc.current-nixos-config.source = ./.;

  # Include a full list of installed packages
  environment.etc.current-system-packages.text = let
    packages = builtins.map (p: "${p.name}") config.environment.systemPackages;
    sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.unique packages);
    formatted = builtins.concatStringsSep "\n" sortedUnique;
  in formatted;

  # Allow edit of /etc/host for temporary mitm:
  environment.etc.hosts.mode = "0644";

  ########################################
  # Hardware
  ########################################
  hardware = {
    cpu.intel.updateMicrocode = true;
    firmware = with pkgs; [ wireless-regdb ];
    opengl = {
      enable = true;
      driSupport = true; # for vulkan
      extraPackages = with pkgs; [
        intel-compute-runtime
        # LIBVA_DRIVER_NAME=iHD (newer)
        intel-media-driver
        # LIBVA_DRIVER_NAME=i965
        vaapiIntel
        vaapiVdpau
      ];
    };
  };
  # Force intel vulkan driver to prevent software rendering:
  environment.variables.VK_ICD_FILENAMES =
    "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";

  ########################################
  # Locale
  ########################################
  time.timeZone = "America/Halifax";
  i18n.defaultLocale = "en_CA.UTF-8";

  ########################################
  # Boot
  ########################################
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.zfs.enableUnstable = true;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    turbostat
  ];
  boot.kernelParams = [
    "workqueue.power_efficient=1"
    "battery.cache_time=10000"
  ];
  powerManagement.enable = true;

  boot.tmpOnTmpfs = true;

  ########################################
  # ZFS
  ########################################
  boot.supportedFilesystems = [ "zfs" ];

  ########################################
  # Network
  ########################################
  networking = {
    hostName = "dn";
    hostId = "822380ad";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    usePredictableInterfaceNames = false;
    useDHCP = false; # deprecated
    wireless.enable = false;
    wireless.iwd.enable = true;
  };


  ########################################
  # Sound
  ########################################
  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true; # for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ########################################
  # Desktop Environment
  ########################################
  programs.qt5ct.enable = true;
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      grim # screenshot
      libinput
      networkmanagerapplet
      papirus-icon-theme
      slurp # select area for screenshot
      swayidle
      swaylock
      waybar
      wl-clipboard
      wofi
      xwayland
      wdisplays

      gtk-engine-murrine
      gtk_engines
      gsettings-desktop-schemas
      lxappearance
      gnome3.adwaita-icon-theme
    ];
  };
  programs.waybar.enable = true;
  xdg.icons.enable = true;

  ########################################
  # Services
  ########################################
  services = {
    fwupd.enable = true;
    openssh.enable = false;
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
    zerotierone.enable = true;
  };

  ########################################
  # Systemd
  ########################################
  # Allow larger coredumps
  systemd.coredump.extraConfig = ''
    #Storage=external
    #Compress=yes
    #ProcessSizeMax=2G
    ProcessSizeMax=10G
    #ExternalSizeMax=2G
    ExternalSizeMax=10G
    #JournalSizeMax=767M
    #MaxUse=
    #KeepFree=
  '';

  ########################################
  # Fonts
  ########################################
  fonts = {
    fonts = with pkgs; [
      fira-code
      font-awesome # Used by waybar
    ];
    fontconfig = { defaultFonts = { monospace = [ "Fira Code" ]; }; };
  };

  ########################################
  # User
  ########################################
  programs.fish.enable = true;
  programs.vim.defaultEditor = true;
  users.users.kenny = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "docker" "networkmanager" "wheel" ];
  };

  ########################################
  # Crypto
  ########################################
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ########################################
  # Containers
  ########################################
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };

  ########################################
  # Security
  ########################################
  programs.browserpass.enable = true;
  programs.firejail = {
    enable = true;
    wrappedBinaries = { teams = "${lib.getBin pkgs.teams}/bin/teams"; };
  };

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; with config.boot.kernelPackages; [
    # General
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    bc
    borgbackup
    brightnessctl
    chromium
    (firefox.override { forceWayland = true; })
    fzf
    google-chrome
    htop
    httpie
    kitty
    libusb1
    libva-utils
    p7zip
    plocate
    python3
    tmux
    xdg-utils

    # Password management
    (pass.override {
      x11Support = false;
      waylandSupport = true;
    })
    qtpass
    yubikey-manager
    yubikey-personalization

    # Sound
    pavucontrol
    pamixer
    pulseeffects-pw

    # Video
    intel-gpu-tools
    v4l_utils

    # Graphics
    glxinfo
    mesa_glu

    # System management
    bcc
    killall
    fwupd
    nixfmt
    powertop
    pstree
    turbostat

    # Networking
    openconnect

    # Communication
    irssi
    signal-desktop
    slack
    # teams -- Included in firejail
    (weechat.override {
      configure = { availablePlugins, ... }: {
        # Only link with Python plugins
        plugins = with availablePlugins; [ python ];
        # `weechat` will auto load the following plugins:
        scripts = with pkgs.weechatScripts; [ wee-slack weechat-matrix ];
      };
    })

    # Email
    mutt
    w3m
    urlview

    # Development
    any-nix-shell
    aws-adfs
    awscli2
    bintools
    clang
    direnv
    file
    gdb
    gh
    gnumake
    jq
    llvm
    manpages
    nix-direnv
    parallel
    perf
    direnv
    git
    rustup
    vscode-fhs # TODO: build with extensions
  ];
}
