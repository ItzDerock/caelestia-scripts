{
  description = "A Nix flake for caelestia";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Python environment with the required deps
        pythonWithPkgs = pkgs.python3.withPackages (ps: [
          ps.materialyoucolor
        ]);

        caelestiaPkgs = with pkgs; [
          # stuff listed in the install script
          git
          hyprpaper
          imagemagick
          wl-clipboard
          fuzzel
          socat
          foot
          jq
          pythonWithPkgs
          xdg-user-dirs
          grim
          swappy
          fish

          # Font and icon dependencies
          nerd-fonts.jetbrains-mono
          material-design-icons 
          ibm-plex
          jetbrains-mono
          fd

          # hyprland is assumed to be installed by the user
        ];
      in
      {
        packages.caelestia = pkgs.stdenv.mkDerivation {
          pname = "caelestia";
          version = "0.1.1"; 

          # Use the current directory as the source for the build
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = caelestiaPkgs;

          installPhase = ''
            runHook preInstall

            # Create directories in the output path
            install -d $out/bin
            install -d $out/libexec/caelestia

            # Copy all source files and directories to libexec, excluding the flake files.
            shopt -s dotglob
            for item in *; do
              case "$item" in
                flake.nix|flake.lock)
                  # Skip flake files
                  ;;
                *)
                  # Copy everything else
                  cp -a --no-preserve=ownership "$item" "$out/libexec/caelestia/"
                  ;;
              esac
            done

            # Create a wrapper script in the bin directory that executes main.fish
            makeWrapper ${pkgs.fish}/bin/fish $out/bin/caelestia \
              --add-flags "$out/libexec/caelestia/main.fish"

            # Install the fish completions
            install -d $out/share/fish/completions
            install -Dm644 $out/libexec/caelestia/completions/caelestia.fish $out/share/fish/completions/caelestia.fish

            runHook postInstall
          '';
        };

        # Set a default package for `nix build` and `nix run`
        defaultPackage = self.packages.${system}.caelestia;
      });
}
