{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
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
      unstable = import <nixos-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

  # Include current config:
  environment.etc.current-nixos-config.source = ./.;

  # Include a full list of installed packages
  environment.etc.current-system-packages.text =
  let
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

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.tmpOnTmpfs = true;

  ########################################
  # ZFS
  ########################################
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.trim.enable = true;

  ########################################
  # Network
  ########################################
  networking = {
    hostName = "dn";
    hostId = "822380ad";
    networkmanager.enable = true;
    usePredictableInterfaceNames = false;
    useDHCP = false;  # deprecated
    wireless.enable = false;
  };

  services.resolved.enable = true;

  ########################################
  # Sound
  ########################################
  # Enable sound.
  sound.enable = true;
  security.rtkit.enable = true;  # for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ########################################
  # Desktop Environment
  ########################################
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swayidle
      swaylock
      waybar
      wl-clipboard
      wofi
      xwayland
    ];
  };
  programs.waybar.enable = true;

  ########################################
  # Services
  ########################################
  services = {
    pcscd.enable = true;
    fwupd.enable = true;
    zerotierone.enable = true;
    openssh.enable = false;
    udev.packages = [ pkgs.yubikey-personalization ];
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
      fira-code-symbols
      font-awesome  # Used by waybar
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Code" ];
      };
    };
  };

  ########################################
  # User
  ########################################
  programs.fish.enable = true;
  programs.vim.defaultEditor = true;
  users.users.kenny = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
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
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    # General
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    borgbackup
    brightnessctl
    chromium
    firefox
    fwupd
    fzf
    google-chrome
    htop
    httpie
    kitty
    libusb1
    libva-utils
    p7zip
    pass
    pulseaudio  # for pactl to adjust volume, other options?
    tmux
    xdg-utils
    yubikey-manager
    yubikey-personalization

    # Communication
    signal-desktop
    slack
    sqlite

    # Development
    any-nix-shell
    aws-adfs
    awscli2
    capnproto
    clang_12
    file
    gdb
    gnumake
    jq
    llvm_12
    llvmPackages_12.bintools
    manpages
    parallel
    config.boot.kernelPackages.perf
    direnv
    git
    rustup
    vscode-fhs  # TODO: build with extensions
  ];
}
