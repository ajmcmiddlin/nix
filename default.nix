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
      "/etc/nixos/sw-kibana.nix"
    ];

  nix.binaryCaches = [
    "https://hydra.qfpl.io"
    "https://cache.nixos.org"
    "https://nixcache.reflex-frp.org"
  ];

  nix.binaryCachePublicKeys = [
    "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
    "qfpl.io:xME0cdnyFcOlMD1nwmn6VrkkGgDNLLpMXoMYl58bz5g="
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
  };

  # backlight brightness
  hardware.brightnessctl.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.hostName = "${machine}";

  # Do NAT for a container through WiFi
  # networking.nat.enable = true;
  # networking.nat.internalInterfaces = ["ve-sw-kibana+"];
  # networking.nat.externalInterface = "wlp2s0";

  # Tell network manager not to mess with our container interfaces
  # networking.networkmanager.unmanaged = ["interface-name:ve-*"];

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_AU.UTF-8";
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Zero configuration DNS broadcast
  services.avahi.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us";
    #desktopManager.default = "none";
    #desktopManager.xterm.enable = false;
    # displayManager.slim.defaultUser = "andrew";
    # Try SLiM as the display manager
    displayManager.lightdm.enable = true;
    xkbOptions = "ctrl:nocaps";

    # windowManager.default = "xmonad";
    # windowManager.xmonad = {
    #   enable = true;
    #   enableContribAndExtras = true;
    #   extraPackages = haskellPackages : [haskellPackages.taffybar];
    # };

    # synaptics = {
    #   enable = true;
    #   twoFingerScroll = true;
    #   horizontalScroll = true;
    #   tapButtons = true;
    #   palmDetect = true;
    #   additionalOptions = ''
    #   Option            "VertScrollDelta"  "-111"
    #   Option            "HorizScrollDelta" "-111"
    #   '';
    # };

    libinput = {
      enable = true;
      naturalScrolling = true;
    };
  };

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

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
