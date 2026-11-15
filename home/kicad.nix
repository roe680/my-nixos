{ pkgs, lib, ... }:
let
  kicad-x11 = pkgs.symlinkJoin {
    name = "kicad-x11";
    paths = [ pkgs.kicad ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --set GDK_BACKEND x11
      done
    '';
  };
in
{
  home.packages = [ (lib.hiPrio kicad-x11) ];
}
