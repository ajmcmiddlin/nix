# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ machine, enableVirtualBoxExtensions ? true }:
{ config, pkgs, ... }:
let
  pwd = ./.;
  home-manager-src = import "${pwd}/deps/home-manager";
in
{
  # Needed for corefonts
  nixpkgs.config.allowUnfree = true;

  # nixpkgs.overlays = [ (import /home/andrew/.config/nixpkgs/overlays) ];

  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      "${pwd}/machine.${machine}.nix"
      "${home-manager-src}/nixos"
      "/etc/nixos/shares.${machine}.nix"
    ];

  nix.binaryCaches = [
    "https://cache.nixos.org"
    "https://nixcache.reflex-frp.org"
  ];

  nix.binaryCachePublicKeys = [
    "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  sound.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    daemon.config = {
      # Allow app volumes to be set independently of master
      flat-volumes = "no";
    };
    # Get a lightweight package by default. Need full to support BT audio.
    package = pkgs.pulseaudioFull;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.hostName = "${machine}";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_AU.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts  # Micrsoft free fonts
      inconsolata  # monospaced
      liberation_ttf
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      source-code-pro
      terminus_font # for hidpi screens, large fonts
      ubuntu_font_family  # Ubuntu fonts
    ];
  };

  # Set your time zone.
  time.timeZone = "Australia/Brisbane";

  # SEE .nixpkgs/config.nix for installed packages
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = (with pkgs; [
    exfat
    exfat-utils
    fuse_exfat

    neovim

    pavucontrol
    unzip
    zip
  ]);

  programs.bash.enableCompletion = true;
  programs.ssh.startAgent = true;
  programs.wireshark.enable = true;

  # Enable VirtualBox (don't install the package)
  virtualisation.virtualbox.host.enable = true;
  # NOTE: this eats a source build of VirtualBox. Disable if a rebuild is taking too long.
  virtualisation.virtualbox.host.enableExtensionPack = enableVirtualBoxExtensions;
  virtualisation.docker.enable = true;

  # List services that you want to enable:

  services.unifi = {
    enable = true;
  };

  services.synergy.client = {
    enable = true;
    serverAddress = "192.168.1.101";
    screenName = "stevie";
  };

  services.gvfs = {
    enable = true;
    package = pkgs.lib.mkForce pkgs.gnome3.gvfs;
  };

  # Enable yubikey
  services.pcscd.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # Enable upower service - used by taffybar's battery widget
  services.upower.enable = true;
  powerManagement.enable = true;

  # Zero configuration DNS broadcast
  services.avahi.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us";
    # Needed for home manager now apparently?
    # https://github.com/rycee/home-manager/issues/1116
    desktopManager.xterm.enable = true;
    xkbOptions = "ctrl:nocaps";

    libinput = {
      enable = true;
      naturalScrolling = false;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  home-manager.users.andrew = import ./home-manager "${machine}";
  users.extraUsers.andrew = {
    createHome = true;
    extraGroups = ["wheel" "video" "audio" "disk" "networkmanager" "docker" "vboxusers" "input" "wireshark"];
    group = "users";
    home = "/home/andrew";
    isNormalUser = true;
    shell = pkgs.zsh;
    uid = 1000;
    openssh.authorizedKeys.keys = (import /etc/nixos/authorized-keys.nix);
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?
}
