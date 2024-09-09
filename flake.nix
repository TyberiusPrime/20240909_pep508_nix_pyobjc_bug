
{
  description = "A basic flake using uv2nix";
  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/24.05";
      uv2nix.url = "github:/adisbladis/uv2nix";
      uv2nix.inputs.nixpkgs.follows = "nixpkgs";
      uv2nix_hammer_overrides.url = "/amy/ffs/e/20240909_FFinkernagel_uv2nix/builds/hammer_build_pyobjc_10.3.1/overrides";
      uv2nix_hammer_overrides.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    uv2nix,
    uv2nix_hammer_overrides,
    ...
  }: let
    inherit (nixpkgs) lib;

    workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    # Manage overlays
    overlay = let
      # Create overlay from workspace.
      overlay' = workspace.mkOverlay {
        sourcePreference = "wheel";
      };
      # work around for packaging must-not-be-a-wheel and is best not overwritten
      overlay'' = pyfinal: pyprev: let
        applied = overlay' pyfinal pyprev;
      in
        lib.filterAttrs (n: _: n != "packaging" && n != "tomli" && n != "pyproject-hooks") applied;

       overrides = (uv2nix_hammer_overrides.overrides pkgs);
    in
      lib.composeExtensions overlay'' overrides;

    python = pkgs.python312.override {
      self = python;
      packageOverrides = overlay;
    };
  in {
    packages.x86_64-linux.default = python.pkgs.app;
    # TODO: A better mkShell withPackages example.
  };
 }
