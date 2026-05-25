{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "roe"; # ← 変更
        email = "dayeziji192@gmail.com"; # ← 変更
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      diff.tool = "difftastic";
      merge.conflictstyle = "zdiff3";
      signing.format = "openpgp";
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.gitui.enable = true;
  
  programs.mise = {
    enable = true;
    enableNushellIntegration = true;
  };

  home.packages = with pkgs; [
    # Task runner
    just

    # NixOS / Nix tooling
    nh
    nvd
    nix-output-monitor
    comma
    nix-index
    nix-tree

    # Nix lint/format tools
    nixfmt
    statix
    deadnix
  ];
}
