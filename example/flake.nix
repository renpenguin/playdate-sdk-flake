{
  inputs = {
    playdate-sdk.url = "github:RegularTetragon/playdate-sdk-flake";
  };
  outputs = {self, nixpkgs, playdate-sdk, ...}: 
  let system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      stdenv = pkgs.stdenv;
      playdate-sdk-pkg = playdate-sdk.packages.${system}.default;
  in
  {
    devShells.${system}.default = with stdenv; pkgs.mkShell {
      packages = [playdate-sdk-pkg];
      shellHook = ''
      export PLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK
      '';
    };
    packages.${system} = {
      default = self.packages.${system}.playdate-example;
      playdate-example = with stdenv; mkDerivation rec {
        pname = "playdate-example";
        version = "1.0.0";
        src = with pkgs.lib.fileset; toSource {
          root = ./.;
          fileset = unions [
            ./CMakeLists.txt
            ./src
            ./Source
          ];
        };
        outName = "hello_world.pdx";
        nativeBuildInputs = [playdate-sdk-pkg pkgs.gcc-arm-embedded pkgs.cmake];
        buildInputs = [ ];
        cmakeFlags = ["-DPLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK"];
        configurePhase =  ''
        export PLAYDATE_SDK_PATH=${playdate-sdk-pkg}
        mkdir build
        cd build
        cmake ..
        make
        cd ..
        '';
        installPhase = ''
          export PLAYDATE_SDK_PATH=`pwd`/.PlaydateSDK
          runHook preInstall
          cp -r . $out
          runHook postInstall
        '';
      };
      playdate-example-arm = self.packages.${system}.playdate-example.overrideAttrs (final: prev: {
        pname = prev.pname + "-arm";
        cmakeFlags = ["-DCMAKE_TOOLCHAIN_FILE=${playdate-sdk-pkg}/C_API/buildsupport/arm.cmake"];
      });
    };
  };
}
