{
  description = "Apollo - an Odin/ImGui/ImPlot synthesiser playground";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    odin-src = {
      url = "github:odin-lang/Odin/dev-2026-09";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      odin-src,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          odin = pkgs.odin.overrideAttrs (old: {
            version = "dev-2026-09";
            src = odin-src;
            postPatch = (old.postPatch or "") + ''
              substituteInPlace build_odin.sh \
                --replace-fail 'GIT_DATE=$(date +"%Y-%m")' 'GIT_DATE=2026-09'
            '';
          });

          linuxNativeInputs = with pkgs; [
            libGL
            vulkan-loader
            libx11
            libxrandr
            libxinerama
            libxcursor
            libxi
            libxext
            libxxf86vm
          ];

          apollo-native = pkgs.stdenv.mkDerivation {
            pname = "apollo-native";
            version = "0.1.0";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./CMakeLists.txt
                ./vendor
              ];
            };

            nativeBuildInputs = with pkgs; [
              cmake
              ninja
              pkg-config
            ];
            buildInputs = linuxNativeInputs;

            # GLFW loads graphics entry points dynamically. Use immutable Nix
            # store paths instead of relying on global /usr/lib names.
            NIX_CFLAGS_COMPILE = toString [
              "-D_GLFW_GLX_LIBRARY=\"${pkgs.lib.getLib pkgs.libGL}/lib/libGLX.so.0\""
              "-D_GLFW_EGL_LIBRARY=\"${pkgs.lib.getLib pkgs.libGL}/lib/libEGL.so.1\""
              "-D_GLFW_OPENGL_LIBRARY=\"${pkgs.lib.getLib pkgs.libGL}/lib/libGL.so.1\""
              "-D_GLFW_GLESV1_LIBRARY=\"${pkgs.lib.getLib pkgs.libGL}/lib/libGLESv1_CM.so.1\""
              "-D_GLFW_GLESV2_LIBRARY=\"${pkgs.lib.getLib pkgs.libGL}/lib/libGLESv2.so.2\""
              "-D_GLFW_VULKAN_LIBRARY=\"${pkgs.lib.getLib pkgs.vulkan-loader}/lib/libvulkan.so.1\""
            ];

            strictDeps = true;
          };

          apollo = pkgs.stdenv.mkDerivation {
            pname = "apollo";
            version = "0.1.0";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./src
                ./vendor/odin
              ];
            };

            nativeBuildInputs = [
              odin
              pkgs.makeWrapper
            ];
            buildInputs = [
              apollo-native
            ]
            ++ linuxNativeInputs;

            dontConfigure = true;

            buildPhase = ''
              runHook preBuild
              odin build src \
                -collection:apollo=vendor/odin \
                -extra-linker-flags:"-L${apollo-native}/lib" \
                -out:apollo \
                -o:speed
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin
              install -Dm755 apollo $out/bin/apollo
              wrapProgram $out/bin/apollo \
                --prefix LD_LIBRARY_PATH : ${nixpkgs.lib.makeLibraryPath ([ apollo-native ] ++ linuxNativeInputs)}
              runHook postInstall
            '';
          };
        in
        {
          inherit apollo apollo-native odin;
          default = apollo;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.apollo}/bin/apollo";
          meta.description = "Run the Apollo synthesiser UI";
        };
      });

      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          packages = self.packages.${system};
          nativeInputs = with pkgs; [
            libGL
            vulkan-loader
            libx11
            libxrandr
            libxinerama
            libxcursor
            libxi
            libxext
            libxxf86vm
          ];
          nativeBuild = ''
            cmake -S . -B build/native -G Ninja -DCMAKE_BUILD_TYPE=Debug
            cmake --build build/native
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              packages.odin
              pkgs.ols
              pkgs.cmake
              pkgs.ninja
              pkgs.pkg-config
            ]
            ++ nativeInputs
            ++ [
              (pkgs.writeShellApplication {
                name = "apollo-build";
                runtimeInputs = [
                  packages.odin
                  pkgs.cmake
                  pkgs.ninja
                ];
                text = nativeBuild + ''
                  odin build src \
                    -collection:apollo=vendor/odin \
                    -extra-linker-flags:"-L$PWD/build/native/lib" \
                    -out:build/apollo \
                    "$@"
                '';
              })
              (pkgs.writeShellApplication {
                name = "apollo-run";
                runtimeInputs = [
                  packages.odin
                  pkgs.cmake
                  pkgs.ninja
                ];
                text = nativeBuild + ''
                  export LD_LIBRARY_PATH="$PWD/build/native/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                  odin run src \
                    -collection:apollo=vendor/odin \
                    -extra-linker-flags:"-L$PWD/build/native/lib" \
                    -out:build/apollo \
                    -- "$@"
                '';
              })
            ];

            LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath [
              packages.apollo-native
              pkgs.libGL
            ];
          };
        }
      );
    };
}
