{ lib }:

let
  inherit (builtins)
    readDir
    ;

  inherit (lib.attrsets)
    filterAttrs
    mapAttrs
    ;

in
rec {
  # Package paths for a directory
  #
  # Example:
  #   pkgs/
  #     default.nix
  #     openssl/
  #       default.nix
  #     curl/
  #       default.nix
  #
  # directoryNames ./pkgs -> { openssl = ./pkgs/openssl; curl = ./pkgs/curl; }
  #
  # Type: Path -> AttrSet Path
  directoryNames = baseDirectory:
    let
      dirs = filterAttrs (_: v: v == "directory") (readDir baseDirectory);
    in
    mapAttrs
      (name: _: baseDirectory + "/${name}")
      dirs;


  # This is expected to be passed a directory which contains subdirectories which
  # correspond to packages.
  # Example:
  #   pkgs/
  #     openssl/
  #       default.nix
  #     curl/
  #       default.nix
  # In this case, `pkgs/` would be the subdirectory, and openssl and curl
  # would be added through the resulting overlay
  #
  # Type: Path -> Overlay
  mkAutoCalledPackageDir = baseDirectory:
    let
      namesForDir = directoryNames baseDirectory;
    in
    self: _super:
      mapAttrs
        (_: value: self.callPackage value { })
        namesForDir;

  # This is similar to mkAutoCalledPackageDir, but expects the directories
  # to be using the mkManyVariant paradigm.
  # See: https://github.com/ekala-project/eeps/blob/auto-call-many-variants/eeps/0006-auto-call-many-variants.md
  #
  # Type: Path -> Overlay
  mkAutoCalledManyVariantsDir = baseDirectory:
    let
      namesForDir = directoryNames baseDirectory;
    in
    self: _super:
      mapAttrs
        (_name: value:
          let
            variants = self.callFromScope value { };
          in
          self.callPackage variants { }
        )
        namesForDir;

}


