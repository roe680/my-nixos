{ config, ... }:

{
  # agenix secrets definition scaffold
  # age.secrets."restic-password" = {
  #   file  = ./secrets/restic-password.age;
  #   owner = "user";
  # };
  #
  # Generate encrypted secret:
  #   agenix -e secrets/restic-password.age
  #
  # Put public keys in:
  #   secrets/secrets.nix
  #
  # Example:
  #   let user = "ssh-ed25519 AAAA...";
  #   in { "restic-password.age".publicKeys = [ user ]; }
}
