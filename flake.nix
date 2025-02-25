{
  description = "Build a dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Allows to define modifications for packages. Ideals to make packages work
        # with specific versions.
        overlay = (final: prev:
          {
            # Use yarn with a different nodejs version
            # yarn = prev.yarn.override { nodejs = final.pkgs.nodejs-16_x; };

            # Refer to https://nixos.wiki/wiki/Overlays
          });

        # The packages for this system and any defined overlay
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

        # Packages required for building
        nativeBuildInputs = with pkgs; [
          # Compilers/Toolchains
          clang_20
          gcc14

          # Makers
          ninja
          cmake
          cmakeCurses

          # Styler, Linter, other generators
          ccache
          cppcheck
          nodePackages.prettier # JSON is everywhere. Make it pretty
          cmake-format # Make cmake files look nice
          clang-tools # clang-tidy, clang-format and others

          # Utils
          doxygen
          graphviz-nox

          # Packager to use and its dependencies:
          vcpkg
          pkg-config
        ];

        # Packages required at runtime
        buildInputs = with pkgs; [ ];

        # Any script to run while activating the shell? Perfect for activating
        # Python VENV, set env vars and more.
        #
        # HINT: you can directly reference paths from packages using:
        #       ${pkgs.emscripten}/bin/em++
        shellHook = ''
          echo "Hello `whoami`. Dev env loaded. Have fun!"
          echo "use:"
          echo "  * Config: $ cmake --preset x64-release-clang"
          echo "  *  Build: $ cmake --build --preset x64-release-clang"
          echo ""
          cmake --list-presets
        '';
      in {
        devShells.default = pkgs.mkShell {
          inherit buildInputs nativeBuildInputs shellHook;

          # Ensure that prebuild binaries installed by pip/conda can find the sys libs
          #LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc pkgs.zlib ];

          # Make sure cmake can use the vcpkg toolchain file
          VCPKG_ROOT = "${pkgs.vcpkg}/share/vcpkg";
        };
      });
}
