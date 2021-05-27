machine:
{ config, pkgs, ... }:
let
  unstable = import <unstable> { config.allowUnfree = true; };

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

  corePackages = pkgs: with pkgs; [
    arandr
    aspell
    aspellDicts.en
    cabal2nix
    baobab
    bind
    brightnessctl
    # calibre
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
    imagemagick
    inkscape
    keepassx
    libreoffice
    maim
    gnome3.nautilus

    # needed for blueman to save settings
    gnome3.gnome_settings_daemon
    gnome3.dconf

    nethogs
    networkmanagerapplet
    nextcloud-client
    nix-prefetch-scripts
    nix-du
    obs-studio
    owncloud-client
    p7zip
    pandoc
    pass
    powertop
    python3
    qtpass
    ranger
    remmina
    samba
    unstable.signal-desktop
    slop
    syncthing
    telnet
    thunderbird
    tigervnc
    # torbrowser
    # tor-browser-bundle-bin
    transmission-gtk
    udisks2
    upower
    volumeicon
    wget
    which
    xclip
    xorg.xev
    xournal
    xscreensaver
    yubioath-desktop

    # Bar + tray
    haskellPackages.xmobar
    haskellPackages.libmpd
    
    # For clipboard syncing
    xsel
    parcellite
    xdotool
  ];

  games = pkgs: with pkgs; [
    #unstable.crawlTiles
    steam
    discord
  ];

  devPackages = pkgs: with pkgs; [
    ansible
    binutils
    docker_compose
    git-crypt
    git-lfs
    gitAndTools.gitflow
    gitAndTools.gitRemoteGcrypt
    gnumake
    graphviz
    jq
    nixops
    patchelf
    postgresql
    silver-searcher
    slack
    sqlite-interactive
    sublime3
    unstable.teams
    vagrant
    wireshark
    wxhexeditor
  ];

  mediaPackages = pkgs: with pkgs; [
    mplayer
    ffmpeg
    spotify
    vlc
    unstable.youtube-dl
    openshot-qt
  ];

  recordingPackages = pkgs: with pkgs; [
    ardour
    infamousPlugins
    audacity
    unstable.tuxguitar

    jack2Full
    qjackctl
  ];

  wiimotePackages = pkgs: with pkgs; [
    blueman
    # enableWiimote isn't an option anymore?
    # (pkgs.bluez.override { enableWiimote = true; })
    bluez

    # This comes from an overlay and doesn't quite work atm
    # xf86-input-xwiimote
    xwiimote
  ];

in {
  nixpkgs.overlays = [
    # (import ./home-overlays/obelisk)
    (import ./home-overlays/spacemacs)
    # (import ./home-overlays/taffybar)
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages =
       corePackages pkgs
    ++ mediaPackages pkgs
    ++ devPackages pkgs
    ++ wiimotePackages pkgs
    ++ (
      if (machine == "hermes") then
        (games pkgs) ++ (recordingPackages pkgs)
      else []
    );

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

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "steeef";
    };
    initExtra = ''
      ssh-add -l | grep /home/andrew/.ssh/id_rsa > /dev/null || {
        ssh-add
      }

      # Load .profile when bash invoked as sh to get direnv working with VS Code
      export ENV=~/.profile
    '';
  };

  home.file.".xmobarrc".source = ./dot-files/xmobarrc;
  home.file.".stalonetrayrc".source = ./dot-files/stalonetrayrc;
  services.stalonetray.enable = true;

  # Source in .envrc to tell npm to use a packages directory our user owns.
  home.file.".npm-setup".source = ./dot-files/npm-setup;

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

  programs.vscode = {
    enable = true;
    userSettings = {
      "git.autofetch" = true;
      "vim.useSystemClipboard" = true;
      "editor.minimap.enabled" = false;
      "editor.tabSize" = 2;
      "rewrap.wrappingColumn" = 100;
      "rewrap.autoWrap.enabled" = true;

      "[markdown]" = {
        "editor.wordWrapColumn" = 100;
        "editor.wordWrap" = "wordWrapColumn";
      };
      "[javascript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[javascriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
    };
    # TODO: install and test this stuff/add more extensions
    # haskell.enable;
    # haskell.hie.enable;
    # extensions = with pkgs.vscode-extensions; [
    #   bbenoist.Nix
    #   alanz.vscode-hie-server
    #   justusadam.language-haskell
    # ]
  };

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
  };

  systemd.user.services.ownCloud =
    startupItem {cmd = "${pkgs.owncloud-client}/bin/owncloud"; description = "ownCloud daemon";};

  systemd.user.services.volumeicon =
    startupItem {cmd = "${pkgs.volumeicon}/bin/volumeicon"; description = "volume tray icon";};

  services.lorri.enable = true;

  services.xscreensaver.enable = true;

  services.pasystray.enable = true;
  services.blueman-applet.enable = true;
  # services.flameshot.enable = true;
  # services.unclutter.enable = true;
  services.network-manager-applet.enable = true;

  services.redshift = {
    enable = true;
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
        history = "mod1+grave";
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
