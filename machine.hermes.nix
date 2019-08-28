# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  hostName = "hermes";
  pwd = ./.;
in
{
  imports = [ "${pwd}/shares.${hostName}.nix" ];
  nix.buildCores = 2;

  networking.hostName = "${hostName}";

  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [8080];
  };

  boot.kernelModules = [ "snd-seq" "snd-rawmidi" ];

  # LUKS root device
  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/sda2";
      preLVM = true;
    }
  ];

  hardware.pulseaudio.package = pkgs.pulseaudioLight.override { jackaudioSupport = true; };

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
