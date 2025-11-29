{ lib }:

let
  inherit (builtins)
    readDir
    ;

  inherit (lib.attrsets)
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    ;

in
rec {
  # Package paths for a directory, this is intened to be used with
  # builtins.readDir, in which the contents can use this function to map over
  # the results
  # Type: Path -> _ -> String -> AttrsOf Path
  mkNamesForDirectory = baseDirectory: _: type:
    if type != "directory" then
    # Ignore files, and only assume that directories will be imported by default
      { }
    else
      mapAttrs
        (name: _: baseDirectory + "/${name}")
        (readDir (baseDirectory));


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
      namesForDir = mkNamesForDirectory baseDirectory;
      # This is defined up here in order to allow reuse of the value (it's kind of expensive to compute)
      # if the overlay has to be applied multiple times
      packageFiles = mergeAttrsList (mapAttrsToList namesForDir (readDir baseDirectory));
    in
    self: super:
      mapAttrs
        (name: value: self.callPackage value { })
        packageFiles;
}


