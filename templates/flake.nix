{
  description = "Local development modules";

  outputs =
    { self, nixpkgs }:
    {
      nixosModules = {
        arduino = import ./nixos/arduino.nix;
        esp = import ./nixos/esp.nix;
      };

      homeManagerModules = {
        rust = import ./home/rust.nix;
        clang = import ./home/clang.nix;
        zig = import ./home/zig.nix;
        cpp = import ./home/cpp.nix;
        bevy = import ./home/bevy.nix;
      };
    };
}
