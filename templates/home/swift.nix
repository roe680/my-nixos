{ pkgs, ... }:
{
  home.packages = with pkgs; [
    swift
    swift-format
    sourcekit-lsp
  ];

  programs.helix.languages = {
    language = [
      {
        name = "swift";
        auto-format = true;
        language-servers = [ "sourcekit-lsp" ];
      }
    ];

    language-server.sourcekit-lsp = {
      command = "${pkgs.sourcekit-lsp}/bin/sourcekit-lsp";
    };
  };
}
