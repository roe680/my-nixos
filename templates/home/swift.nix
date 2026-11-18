{ pkgs, ... }:
{
  home.packages = with pkgs; [
    swift
    swiftpm
    swift-format
    sourcekit-lsp
    lldb
    clang
    pkg-config
    ncurses
    libedit
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
