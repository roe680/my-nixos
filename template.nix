{ ... }:
{
  nix.registry = {
    # 🌟 「to」という名前の独立したレジストリを完璧な型で定義
    to = {
      # NixOSが要求する「flake型（attribute set）」の構造を完全に満たす記述です
      flake = {
        outPath = ./templates;
      };
    };
  };
}
