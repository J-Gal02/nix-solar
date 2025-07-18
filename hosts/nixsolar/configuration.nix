{ config, pkgs, lib, ... }:

let
  # Sensitive values are now set via imports or nixos-rebuild --option, not hardcoded
  user = "nixsolar";
  interface = "wlan0";
  hostname = "nixos-pi4";
  # These are set via secrets.nix or passed at build time
  password = config.deployment.secrets.userPassword;
  SSID = config.deployment.secrets.wifiSSID;
  SSIDpassword = config.deployment.secrets.wifiPassword;
in {

  imports = [
    # Import a secrets file (not tracked in git)
    ./secrets.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = hostname;
    wireless = {
      enable = true;
      networks."${SSID}".psk = SSIDpassword;
      interfaces = [ interface ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim git htop curl wget tmux neofetch
  ];

  # Enable SSH
  services.openssh.enable = true;

  # Enable Jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Enable flake support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
  };

  # Optionally, you can add more power-saving tweaks here
  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";

  # Custom options for secrets
  options.deployment.secrets = {
    userPassword = lib.mkOption {
      type = lib.types.str;
      description = "User password for nixsolar user.";
    };
    wifiSSID = lib.mkOption {
      type = lib.types.str;
      description = "WiFi SSID.";
    };
    wifiPassword = lib.mkOption {
      type = lib.types.str;
      description = "WiFi password.";
    };
  };
}