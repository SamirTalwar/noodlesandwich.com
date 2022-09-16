{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
with pkgs;
mkShell {
  buildInputs = [
    niv
    nixpkgs-fmt

    awscli
    bash
    elmPackages.elm
    elmPackages.elm-format
    gnumake
    jq
    nodejs
    terraform
    yarn
  ];
}
