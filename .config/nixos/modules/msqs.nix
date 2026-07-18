# msqs — Facebook Messenger bridge stack for the native QML Messenger client
# (~/repos/msqs). The client is a thin Matrix client; the actual Messenger
# connection (login, and the E2EE-by-default personal chats) is handled by
# mautrix-meta against a local single-user Synapse. Everything binds to
# 127.0.0.1 only; no federation, no registration.
#
# One-time setup after the first rebuild (see also the msqs README):
#   1. sudo sh -c 'umask 077; tr -dc a-z0-9 </dev/urandom | head -c 48 \
#        > /var/lib/matrix-synapse/registration-shared-secret'
#      (then rebuild again so Synapse picks it up)
#   2. register_new_matrix_user -u martin -p <password> --no-admin \
#        -k "$(sudo cat /var/lib/matrix-synapse/registration-shared-secret)" \
#        http://127.0.0.1:8008
#   3. Put homeserver/user/password in ~/.config/msqs/config.toml, start msqs,
#      and log the bridge into Messenger from the "Bridge bot" chat (see README).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "msqs.localhost";
  port = 8008;
in
{
  # mautrix-meta links libolm (CVE-2024-45191..93, unmaintained upstream). It
  # is only used for Matrix end-to-bridge encryption, which this setup turns
  # off (loopback-only homeserver); the Messenger-side E2EE is a separate
  # whatsmeow-based implementation and does not involve libolm.
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = domain;
      public_baseurl = "http://127.0.0.1:${toString port}";
      # Client API only, loopback only. No federation resource is exposed and
      # the whitelist below refuses any that would slip through.
      listeners = [
        {
          bind_addresses = [ "127.0.0.1" ];
          inherit port;
          tls = false;
          type = "http";
          x_forwarded = false;
          resources = [
            {
              names = [ "client" ];
              compress = false;
            }
          ];
        }
      ];
      federation_domain_whitelist = [ ];
      enable_registration = false;
      # One-time user creation via register_new_matrix_user (setup step above).
      # Optional: absent file just means registration by secret is off.
      registration_shared_secret_path = "/var/lib/matrix-synapse/registration-shared-secret";
      presence.enabled = false;
      report_stats = false;
      database.name = "sqlite3";
    };
  };

  services.mautrix-meta.instances.messenger = {
    enable = true;
    # Adds the generated appservice registration to Synapse and orders the
    # services correctly.
    registerToSynapse = true;
    settings = {
      homeserver = {
        domain = domain;
        address = "http://127.0.0.1:${toString port}";
      };
      network.mode = "messenger";
      appservice = {
        id = "messenger";
        bot = {
          username = "messengerbot";
          displayname = "Messenger bridge bot";
        };
        username_template = "messenger_{{.}}";
      };
      bridge.permissions."@martin:${domain}" = "admin";
      # The nixpkgs module defaults end-to-bridge encryption ON. Off here on
      # purpose: portal rooms only ever exist on this loopback homeserver, and
      # the msqs client is deliberately a plain no-E2EE Matrix client. The
      # Messenger-side E2EE (the part that matters) lives in the bridge's
      # connection to Meta and is unaffected.
      encryption = {
        allow = false;
        default = false;
        require = false;
      };
    };
  };
}
