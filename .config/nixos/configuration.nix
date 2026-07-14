# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  unstable,
  flakePackages,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/dotnet.nix
    ./modules/neovim.nix
    ./modules/roslyn-ls.nix
    ./modules/nodejs.nix
    ./modules/azure-cli.nix
    ./modules/bicep.nix
    ./modules/azure-data-studio.nix
    ./modules/teams-fork.nix
    ./modules/endcord.nix
    ./modules/rust.nix
    ./modules/hemma.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Cap the boot menu (and kernels copied to the ESP) at the 10 newest
  # generations — this is the cold-rollback depth available at the boot screen.
  boot.loader.systemd-boot.configurationLimit = 10;

  # Weekly GC of generations older than 30 days, so the store stays bounded and
  # generations don't re-accumulate (they had piled up to ~200 before). This is
  # independent of configurationLimit above: the limit bounds /boot, this bounds
  # /nix/store. Anything newer than 30 days is always kept.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Blacklist kernel modules that are unused here but serve only as local-root
  # attack surface, auto-loadable by unprivileged users:
  #   algif_aead      - CVE-2026-31431 "Copy Fail" (AF_ALG AEAD page-cache write)
  #   esp4/esp6       - CVE-2026-43284 "Dirty Frag" (xfrm/ESP page-cache write)
  #   rxrpc           - CVE-2026-43500 "Dirty Frag" (RxRPC page-cache write)
  #
  # REDUNDANT for these specific CVEs: all three are fixed at the source in the
  # kernel we now run (6.18.38 >> the May 2026 fixes), so the blacklist no longer
  # provides the patch.
  # KEPT anyway as defence-in-depth: this machine uses no AF_ALG AEAD, no
  # IPsec/ESP VPN, and no AFS/rxrpc, so permanently blocking unprivileged
  # autoload of these modules shrinks the attack surface against *future* bugs in
  # them (this same "unprivileged autoload -> page-cache write -> root" class hit
  # three times in 2026) at zero functional cost.
  boot.blacklistedKernelModules = [
    "algif_aead"
    "esp4"
    "esp6"
    "rxrpc"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Local dev hostnames. SD-API binds to sd-api.dev.sis.se in its launch
  # settings so it can match the local cert SAN — route it to loopback.
  networking.hosts = {
    "127.0.0.1" = [ "sd-api.dev.sis.se" ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  nixpkgs.config.allowUnfree = true;

  # GTK 4.19.2+ removed built-in input method handling, breaking dead keys
  # (e.g. ~ via AltGr) in GTK apps like Ghostty. Setting this to "simple"
  # restores dead key composition without needing a full input method framework.
  # See: https://discourse.nixos.org/t/swedish-keyboard-layout-not-working-after-upgrade-to-25-11/72882/3
  environment.sessionVariables.GTK_IM_MODULE = "simple";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Custom US keyboard layout with Swedish characters (å ä ö on [ ' ;)
  services.xserver.xkb.extraLayouts.us_swedish = {
    description = "English (US, Swedish chars)";
    languages = [
      "eng"
      "swe"
    ];
    symbolsFile = ./us_swedish;
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.martin = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "docker"
    ]; # wheel = sudo, video = brightnessctl without sudo
    packages = with pkgs; [
      tree
    ];
  };

  virtualisation.docker.enable = true;

  programs.niri.enable = true;
  programs.thunderbird.enable = true;

  # XDG Portal for screen sharing on Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  fonts.packages = with pkgs; [
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    inter
    ibm-plex
    roboto
  ];

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Battery monitoring (battery % in the qs-picker bar)
  services.upower.enable = true;

  # Vial (the GUI app for remapping QMK/Vial keyboards, installed below) talks to
  # the keyboard over a /dev/hidraw* device. By default those nodes are root-only,
  # so Vial shows "No devices detected" until we grant the logged-in user access.
  # This udev rule does exactly that: every Vial keyboard reports a USB serial
  # containing the magic string "vial:f64c2b3c", and TAG+="uaccess" hands the
  # active desktop session read/write access to the matching hidraw node (no root,
  # no replugging-as-root). This is Vial's own required setup on Linux, just
  # expressed declaratively for NixOS instead of a hand-placed /etc/udev file.
  # Docs / source of this rule: https://get.vial.today/manual/linux-udev.html
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess"
  '';

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    mkcert
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    ghostty
    kitty
    vial
    tmux
    git
    wget
    fuzzel
    rofi
    gh # gh cli
    zoxide
    eza # modern ls replacement with icons (used by ls/ll/la/lt aliases in .bashrc)
    xwayland-satellite # XWayland bridge for niri, needed by X11 apps
    teams-for-linux
    signal-desktop
    swaybg
    wl-clipboard
    grim # region capture backend for the qs-picker keyboard screenshot (Print)
    imagemagick # crops the frozen grim snapshot for the qs-picker region screenshot
    imv # image viewer for tmqs media enlarging (SLK_MEDIA_VIEWER -> media-viewer.sh)
    mpv # video player for tmqs media enlarging
    aerc # vim-like terminal email client
    w3m # HTML->text renderer used by aerc's html filter
    chafa # renders images to terminal graphics (kitty protocol) for inline aerc images
    jq
    python3
    glib # provides gsettings - a CLI tool that reads/writes GNOME/GTK settings (e.g. dark/light mode preference that apps like Ghostty and Firefox listen to)
    # neovim + LSPs/formatters/tools provided by modules/neovim.nix
    # roslyn-ls provided by modules/roslyn-ls.nix
    # dotnet-sdk_10 provided by modules/dotnet.nix
    television # fuzzy finder TUI
    bat # cat clone with syntax highlighting, used by television for previews
    wev # tool to see keycodes for key input etc
    brightnessctl # brightness control via keyboard brightness keys
    swayosd # on-screen display for brightness/volume changes (26.05 stable is 0.3.1, same as unstable; 0.3.1 still has the DRM-connector SIGABRT — supervised by swayosd.service user unit instead)
    unstable.quickshell # QML desktop-shell toolkit — powers ~/repos/qs-picker (Helium profile picker + bar + notifications; replaced dunst)
    libnotify # provides notify-send for sending desktop notifications (received by qs-picker NotifService)
    pass # password manager (pass)
    terraform
    spotify-player
    wtype # sends keystrokes for the claude-code-notify respond flow (replaced dunst)
    cloc # Count Lines Of Code
    sqlcmd # MS SQL CLI client
    kanshi # dynamic monitor configuration
    sox # audio recording, required by claude code /voice
    pavucontrol # GUI mixer for PipeWire/PulseAudio (route apps between sinks/sources)
    tcpdump # CLI packet capture/analyzer
    postgresql # provides psql for connecting to Postgres (Vercel/Neon/Supabase etc.)
    calc
    nautilus # GNOME Files — GUI file manager (Mod+E in niri)
    yazi # Apparently needed for dsqrd on u (as in upload)
  ]
  # Packages from external flake inputs (helium, claude-code, ...), wired
  # in flake.nix and passed through via specialArgs. See flake.nix `flakePackages`.
  ++ flakePackages;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # PAM service used by the qs-picker ORION lockscreen (~/repos/qs-picker/lock.qml)
  # for password authentication. Named "swaylock" for the pure pam_unix policy;
  # swaylock itself is gone, but lock.qml authenticates against this service.
  security.pam.services.swaylock = { };

  # Passwordless sudo scoped to nixos-rebuild only, so automated/agent-driven
  # rebuilds don't get stuck on the TTY password prompt. Normal sudo still
  # requires a password for everything else.
  security.sudo.extraRules = [{
    users = [ "martin" ];
    commands = [{
      command = "/run/current-system/sw/bin/nixos-rebuild";
      options = [ "NOPASSWD" ];
    }];
  }];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "niri-session";
      user = "martin";
    };
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # 7777 = hemma home dashboard — now opened conditionally (only on the home
  # WiFi) by ./modules/hemma.nix, so it is NOT listed here.
  # networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # mDNS / Bonjour: broadcast nixos.local on the LAN so the phone can reach
  # the notes app by hostname instead of IP.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    # Only the real WiFi interface — otherwise avahi also publishes address
    # records for every docker bridge/veth, and nixos.local resolves to a
    # useless 172.x address (add an ethernet iface here if one appears).
    allowInterfaces = [ "wlp0s20f3" ];
    publish = {
      enable = true;
      addresses = true;
    };
  };
  # nss-mdns refuses to resolve *.local on networks whose router answers
  # unicast DNS for the "local." domain (e.g. Galaxen). This file's presence
  # disables that SOA heuristic so .local always goes via mDNS.
  environment.etc."mdns.allow".text = ''
    .local.
    .local
  '';

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
