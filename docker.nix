{ pkgs, ... }:

{
  # rootless Podman (docker コマンド互換)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Docker に戻す場合:
  # virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    lazydocker
    dive
    kubectl
    kubernetes-helm
    terraform
    awscli2
  ];
}
