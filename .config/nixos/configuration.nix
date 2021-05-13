{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./zerotier-configuration.nix
    ];

  environment.etc.current-nixos-config.source = ./.;
  environment.variables.EDITOR = "vim";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.supportedFilesystems = [ "zfs" ];
  boot.tmpOnTmpfs = true;
  hardware = {
    cpu.intel.updateMicrocode = true;
    firmware = with pkgs; [ wireless-regdb ];
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver  # LIBVA_DRIVER_NAME=iHD (newer)
      vaapiIntel          # LIBVA_DRIVER_NAME=i965
      vaapiVdpau
    ];
  };

  networking.hostName = "dn";
  networking.hostId = "822380ad";
  networking.wireless.enable = false;

  time.timeZone = "America/Halifax";

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      gnupg = pkgs.gnupg.override { libusb1 = pkgs.libusb1; };
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      unstable = import <nixos-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };

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

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable sound.
  sound.enable = true;
  #hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;  # for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.fish.enable = true;
  users.users.kenny = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
  };

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swayidle
      swaylock
      waybar
      wofi
      xwayland
    ];
  };
  programs.waybar.enable = true;
  programs.ssh.startAgent = false;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    gnupg
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
    vim
    yubikey-manager
    yubikey-personalization

    # Communication
    signal-desktop
    slack
    sqlite

    # Development
    aws-adfs
    awscli2
    capnproto
    clang_12
    file
    gdb
    gnumake
    llvm_12
    llvmPackages_12.bintools
    parallel
    direnv
    git
    rustup
    vscode-fhs  # TODO: build with extensions
  ];

  services = {
    fwupd.enable = true;
    zerotierone.enable = true;
    openssh.enable = false;
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

