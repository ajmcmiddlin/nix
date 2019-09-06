machine:
{ config, pkgs, ... }:
let
  restart-taffybar = ''
    echo "Restarting taffybar..."
    $DRY_RUN_CMD rm -fr $HOME/.cache/taffybar/
    $DRY_RUN_CMD systemctl --user restart taffybar.service
  '';

  unstable = import <unstable> {};

  startupItem = {cmd, description}:
    {
      Unit = {
        Description = "${description}";
      };

      Service = {
        ExecStart = "${cmd}";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

in {
  nixpkgs.overlays = [
    (import ./home-overlays/direnv)
    (import ./home-overlays/lorri)
    # (import ./home-overlays/obelisk)
    (import ./home-overlays/spacemacs)
    (import ./home-overlays/taffybar)
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    arandr
    aspell
    aspellDicts.en
    cabal2nix
    bind
    brightnessctl
    calibre
    cifs-utils
    dia
    dmenu
    dropbox
    encfs
    evince
    evtest
    exfat
    feh
    gimp
    ghostscript
    gnupg
  ]++
  ( with haskellPackages; [
    ghcid
    stylish-haskell
    yeganesh
  ]) ++ [
    imagemagick
    inkscape
    keepassx
    libreoffice
    maim
    gnome3.nautilus

    # needed for blueman to save settings
    gnome3.gnome_settings_daemon
    gnome3.dconf

    neovim
    nethogs
    networkmanagerapplet
    nix-prefetch-scripts
    obs-studio
    owncloud-client
    p7zip
    pandoc
    # paperboy
    pass
    powertop
    python3
    qtpass
    ranger
    rfkill
    samba
    unstable.signal-desktop
    slack
    slop
    # For taffybar's SNI tray
    # haskellPackages.status-notifier-item
    syncthing
    telnet
    thunderbird
    tigervnc
    # torbrowser
    # tor-browser-bundle-bin
    transmission-gtk
    udisks2
    upower
    unzip
    volumeicon
    wget
    which
    xclip
    xorg.xev
    xscreensaver
    yubioath-desktop

    # For clipboard syncing
    xsel
    parcellite
    xdotool
  ] ++ [ # GAMES
    #unstable.crawlTiles
    steam
    discord
  ] ++ [ # DEV
    ansible
    binutils
    docker_compose
    git-crypt
    gitAndTools.gitflow
    gitAndTools.gitRemoteGcrypt
    gnumake
    graphviz
    lorri
    nixops
    patchelf
    postgresql
    silver-searcher
    slack
    sqlite-interactive
    sublime3
    vagrant
  ] ++ [ # MEDIA
    mplayer
    ffmpeg
    spotify
    vlc
    unstable.youtube-dl
  ] ++ (if machine == "hermes" then [
    # RECORDING
    ardour
    infamousPlugins
    audacity

    jack2Full
    qjackctl

    # BLUETOOTH
    blueman
    (pkgs.bluez.override { enableWiimote = true; })

    # This comes from an overlay and doesn't quite work atm
    # xf86-input-xwiimote
    xwiimote
  ] else []);

  home.file."bin" = { source = ./dot-files/bin; recursive = true; };
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "firefox";
  };

  programs.home-manager = {
    enable = true;
  };

  programs.direnv.enable = true;
  programs.chromium.enable = true;
  programs.firefox.enable = true;
  programs.fish.enable = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "steeef";
      plugins = ["ssh-agent"];
    };
    initExtraBeforeCompInit = ''
      zstyle :omz:plugins:ssh-agent identities id_rsa
    '';
  };

  home.file.".config/fish/functions" = {
    source = ./dot-files/config/fish/functions;
    recursive = true;
  };

  home.file.".spacemacs".source = ./dot-files/spacemacs;
  home.file.".emacs.d" = {
    source = pkgs.spacemacs;
    recursive = true;
  };
  home.file.".emacs.d/private-ajm" = {
    source = ./dot-files/emacs.d/private;
    recursive = true;
  };
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs.override { inherit (pkgs) imagemagick; };
    # This borks spacemacs when it tries to uninstall tablist.
    # extraPackages = epkgs: with epkgs; [pdf-tools];
  };

  programs.htop.enable = true;
  programs.urxvt = {
    enable = true;
    fonts = ["xft:Source Code Pro:size=11"];
    # keybindings = {
    #   "Shift-Control-C" = "eval:selection_to_clipboard";
    #   "Shift-Control-V" = "eval:paste_clipboard";
    # };
    #transparent = true;
    #shading = 50;
  };

  programs.vscode.enable = true;

  # home.file.".gitmessage".source = ./dotfiles/git/gitmessage;
  programs.git = {
    enable = true;
    userName = "Andrew McMiddlin";
    userEmail = "andrew@ajmccluskey.com";
    ignores = [];
  };

  # programs.zathura.enable = true;

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 36000;
    maxCacheTtl = 36000;
    defaultCacheTtlSsh = 36000;
    maxCacheTtlSsh = 36000;
    enableSshSupport = true;
  };

  # home.file."backgrounds" = {
  #   source = ./backgrounds;
  #   recursive = true;
  # };
  # services.random-background = {
  #   enable = true;
  #   imageDirectory = "%h/backgrounds";
  # };
  # services.screen-locker = {
  #   enable = true;
  #   lockCmd = "xlock -mode blank";
  #   inactiveInterval = 10;
  # };

  systemd.user.services.lorri =
    startupItem {cmd = "${pkgs.lorri}/bin/lorri daemon"; description = "lorri daemon"; };

  systemd.user.services.ownCloud =
    startupItem {cmd = "${pkgs.owncloud-client}/bin/owncloud"; description = "ownCloud daemon";};

  systemd.user.services.volumeicon =
    startupItem {cmd = "${pkgs.volumeicon}/bin/volumeicon"; description = "volume tray icon";};

  services.xscreensaver.enable = true;

  services.xembed-sni-proxy.enable = true;

  services.pasystray.enable = true;
  home.file.".config/taffybar/taffybar.hs" = {
    source = ./dot-files/config/taffybar/taffybar.hs;
    onChange = restart-taffybar;
  };
  # home.file.".config/taffybar/taffybar.css" = {
  #   source = ./dot-files/taffybar/taffybar.css;
  #   onChange = restart-taffybar;
  # };
  services.taffybar.enable = true;
  services.status-notifier-watcher.enable = true;
  services.blueman-applet.enable = true;
  # services.flameshot.enable = true;
  # services.unclutter.enable = true;
  services.network-manager-applet.enable = true;

  services.redshift = {
    enable = true;
    # brightness.day = "1.0";
    # brightness.night = "0.7";
    latitude = "-27.45817";
    longitude = "153.03443";
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Source Code Pro";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        icon_position = "left";
        sort = true;
        alignment = "center";
        geometry = "500x60-15+49";
        browser = "/usr/bin/firefox -new-tab";
        transparency = 10;
        word_wrap = true;
        show_indicators = false;
        separator_height = 2;
        padding = 6;
        horizontal_padding = 6;
        separator_color = "frame";
        frame_width = 2;
      };
      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
        history = "ctrl+grave";
        context = "ctrl+shift+period";
      };
      urgency_low = {
        frame_color = "#3B7C87";
        foreground = "#3B7C87";
        background = "#191311";
        timeout = 4;
      };
      urgency_normal = {
        frame_color = "#5B8234";
        foreground = "#5B8234";
        background = "#191311";
        timeout = 6;
      };
      urgency_critical = {
        frame_color = "#B7472A";
        foreground = "#B7472A";
        background = "#191311";
        timeout = 8;
      };
    };
  };

  xsession = {
    enable = true;
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = hpkgs: [
        hpkgs.xmonad-contrib
        hpkgs.taffybar
      ];
      config = ./dot-files/xmonad/xmonad.hs;
    };
  };

  xresources.extraConfig = ''
  ! special
  *.foreground:   #c5c8c6
  *.background:   #1d1f21
  *.cursorColor:  #c5c8c6
  ! black
  *.color0:       #282a2e
  *.color8:       #373b41
  ! red
  *.color1:       #a54242
  *.color9:       #cc6666
  ! green
  *.color2:       #8c9440
  *.color10:      #b5bd68
  ! yellow
  *.color3:       #de935f
  *.color11:      #f0c674
  ! blue
  *.color4:       #5f819d
  *.color12:      #81a2be
  ! magenta
  *.color5:       #85678f
  *.color13:      #b294bb
  ! cyan
  *.color6:       #5e8d87
  *.color14:      #8abeb7
  ! white
  *.color7:       #707880
  *.color15:      #c5c8c6
  home.language.base = "en_au";
  '';
}
