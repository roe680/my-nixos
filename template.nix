{ ... }:
{
  nix.registry.templates = {
    flake = {
      type = "path";
      path = ./templates;
    };
  };
}
