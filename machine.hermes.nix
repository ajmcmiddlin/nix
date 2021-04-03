# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix.buildCores = 2;


  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [8080];
  };

  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModulePackages = [pkgs.linuxPackages_latest.v4l2loopback];

  # LUKS root device
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/sda2";
      preLVM = true;
    };
  };

  # environment.systemPackages = (with pkgs; [
  #   jack2Full
  # ]);

  users.groups = { realtime = {}; };

  # Set limits for realtime -- used by JACK
  security.pam.loginLimits = [
    { domain = "@realtime";
      type = "-";
      item = "rtprio";
      value = "99";
    }

    { domain = "@realtime";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];

  users.extraUsers.andrew.extraGroups = ["realtime"];
}
