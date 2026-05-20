# agenix recipients template
#
# 使い方:
# 1) 公開鍵（user / host）を実値に置き換える
# 2) 各 .age ファイルに必要な受信者を割り当てる
# 3) 生成:
#    agenix -e secrets/restic-password.age
#
# 例:
#   agenix -r secrets/secrets.nix -e secrets/restic-password.age

let
  # User public key (ssh-ed25519 ...)
  user = "ssh-ed25519 AAAA_REPLACE_WITH_YOUR_USER_PUBLIC_KEY";

  # Host public key (usually from /etc/ssh/ssh_host_ed25519_key.pub)
  host = "ssh-ed25519 AAAA_REPLACE_WITH_YOUR_HOST_PUBLIC_KEY";
in
{
  # Restic password for backups
  "restic-password.age".publicKeys = [ user host ];

  # Optional examples:
  # "github-token.age".publicKeys = [ user ];
  # "s3-credentials.age".publicKeys = [ user host ];
}
