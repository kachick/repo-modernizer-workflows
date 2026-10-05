{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
  };

  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellScriptBin "dprint-fmt" ''
          exec "${lib.getExe pkgs.dprint}" fmt "$@"
        ''
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # nixpkgs-unstable has not received gh-aw 0.89.21 from master yet.
          # In addition, nixpkgs package omits `-X main.isRelease=true`, causing gh-aw to run in dev mode.
          gh-aw = pkgs.gh-aw.overrideAttrs (_old: rec {
            version = "0.89.21";
            src = pkgs.fetchFromGitHub {
              owner = "github";
              repo = "gh-aw";
              tag = "v${version}";
              hash = "sha256-T+YaU0ibxk5e4Y0Z4F4rSRQrXCKgJUE3xQMnDxBHZvQ=";
            };
            vendorHash = "sha256-YydstLwmlQNoE22DAV9zZyWbeXfo0cJmSssRLVkBB/k=";
            ldflags = [
              "-s"
              "-w"
              "-X"
              "main.version=v${version}"
              "-X"
              "main.isRelease=true"
            ];
          });
        in
        {
          default = pkgs.mkShellNoCC {
            # Set NIX_PATH for nixd inlay hints
            env.NIX_PATH = "nixpkgs=${nixpkgs.outPath}";

            buildInputs = [
              gh-aw
            ]
            ++ (with pkgs; [
              # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
              bashInteractive
              findutils # xargs
              nixd
              go-task
              dprint
              typos
              zizmor
              rumdl
            ]);
          };
        }
      );
    };
}
