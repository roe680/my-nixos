{ ... }:
{
  nix.registry.templates = {
    to= {
      type = "path";
      path = ./templates;
    };
  };
}
