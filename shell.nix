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
    gnumake
    jq
    nodejs
    terraform_0_14
    yarn
  ];
}
