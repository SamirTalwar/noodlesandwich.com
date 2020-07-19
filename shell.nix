{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:
with pkgs;
mkShell {
  buildInputs = [
    niv
    nixpkgs-fmt

    bash
    gnumake
    jq
    nodejs
    terraform
    yarn
  ];
}
