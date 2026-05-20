{pkgs, inputs,  ... }:
{
  programs.walker = {
    package = pkgs.walker;
    enable = true;
    runAsService = true; # バックグラウンドで常駐させて起動を高速化
  };

}
