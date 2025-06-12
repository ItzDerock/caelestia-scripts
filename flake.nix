# flake.nix
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

          # for video capture
          wl-screenrec
          glib.bin # provides bin/gdbus

          # hyprland is assumed to be installed by the user
        ];
      in
      {
        packages.caelestia = pkgs.stdenv.mkDerivation {
          pname = "caelestia";
          version = "0.1.1";
          src = ./.;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = caelestiaPkgs;

          installPhase = ''
            runHook preInstall

            install -d $out/bin
            install -d $out/libexec/caelestia
            
            # Copy source files
            shopt -s dotglob
            for item in *; do
              case "$item" in
                flake.nix|flake.lock) ;;
                *) cp -a --no-preserve=ownership "$item" "$out/libexec/caelestia/" ;;
              esac
            done
            
            # Install completions
            install -d $out/share/fish/completions
            install -Dm644 $out/libexec/caelestia/completions/caelestia.fish $out/share/fish/completions/caelestia.fish

            # Create a wrapper that provides the PATH for all dependencies
            makeWrapper ${pkgs.fish}/bin/fish $out/bin/caelestia \
              --prefix PATH : ${pkgs.lib.makeBinPath caelestiaPkgs} \
              --set-default CAELESTIA_DATA_DIR "$out/libexec/caelestia/data" \
              --set-default CAELESTIA_CACHE_DIR "$HOME/.cache/caelestia" \
              --add-flags "$out/libexec/caelestia/main.fish"

            runHook postInstall
          '';
        };

        defaultPackage = self.packages.${system}.caelestia;
      });
}
