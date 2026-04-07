# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/dotnet-devops-auth.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

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
    ]; # wheel = sudo, video = brightnessctl without sudo
    packages = with pkgs; [
      tree
    ];
  };

  programs.niri.enable = true;
  programs.firefox.enable = true;

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

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    ghostty
    neovim
    tmux
    git
    waybar
    wget
    fuzzel
    gh # gh cli
    zoxide
    discord
    vesktop
    xwayland-satellite # XWayland bridge for niri, needed by X11 apps like Discord
    teams-for-linux
    swaybg
    wl-clipboard
    jq
    python3
    glib # provides gsettings - a CLI tool that reads/writes GNOME/GTK settings (e.g. dark/light mode preference that apps like Ghostty and Firefox listen to)
    tree-sitter # nvim-treesitter uses this CLI to download and build parsers
    gcc # C compiler needed by tree-sitter to compile parsers
    nodejs # needed by mason to install typescript-language-server
    dotnet-sdk_10 # needed by mason to install roslyn, csharpier, and bicep-lsp
    fd # fast file finder used by telescope.nvim
    unzip # needed by mason to extract packages
    cargo # needed by mason to build nil (Nix LSP)
    nixfmt # formatter used by nil (Nix LSP)
    fzf # fuzzy finder used by nvim-bqf quickfix filtering
    television # fuzzy finder TUI
    bat # cat clone with syntax highlighting, used by television for previews
    wev # tool to see keycodes for key input etc
    brightnessctl # brightness control via keyboard brightness keys
    swayosd # on-screen display for brightness/volume changes
    dunst # notification daemon
    libnotify # provides notify-send for sending desktop notifications
    pass # password manager (pass)
    azure-cli
    terraform
    spotify-player
    wtype # To be able to send keystrokes to a terminal from dunst notification for claude notifications
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
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
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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
