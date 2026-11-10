# freebuff - Free AI coding assistant (vendored package)
#
# Vendored from b-rodrigues/nixpkgs branch `add-freebuff`
# (pkgs/by-name/fr/freebuff) so the whole nixpkgs fork is no longer needed
# as a flake input for a single package. The upstream darwin branch is
# dropped: this repository only builds Linux hosts. Bump version + hashes
# with ./update.sh (pulls the latest release metadata from the npm registry).
{
  lib,
  stdenv,
  fetchurl,
  buildFHSEnv,
  autoPatchelfHook,
  git,
  ripgrep,
  cacert,
  curl,
  bubblewrap,
}:

let
  version = "0.2.33";

  sources = {
    x86_64-linux = {
      asset = "freebuff-linux-x64.tar.gz";
      hash = "sha256-oB6Ozse/5MiVz4KRMefYU6WjsJLe1a1tO71+0ltLy64=";
    };
    aarch64-linux = {
      asset = "freebuff-linux-arm64.tar.gz";
      hash = "sha256-/vauvw6z07ZvG68ITE2M7RkPmQRyuZLtaOURO0DUgdk=";
    };
  };

  srcInfo =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  meta = {
    description = "Free AI coding assistant";
    homepage = "https://freebuff.com";
    downloadPage = "https://github.com/CodebuffAI/codebuff-community/releases";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ b-rodrigues ];
    mainProgram = "freebuff";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };

  unwrapped = stdenv.mkDerivation (finalAttrs: {
    pname = "freebuff-unwrapped";
    inherit version meta;

    src = fetchurl {
      url = "https://github.com/CodebuffAI/codebuff-community/releases/download/freebuff-v${finalAttrs.version}/${srcInfo.asset}";
      inherit (srcInfo) hash;
    };

    sourceRoot = ".";

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 freebuff -t $out/bin/
      install -Dm644 tree-sitter.wasm -t $out/bin/

      runHook postInstall
    '';
  });

  fhs = buildFHSEnv {
    pname = "freebuff";
    inherit version meta;

    targetPkgs =
      pkgs: with pkgs; [
        unwrapped
        git
        ripgrep
        cacert
        curl
        bubblewrap
      ];

    runScript = "freebuff";

    extraInstallCommands = ''
      mkdir -p $out/share
    '';

    passthru = {
      inherit unwrapped;
      updateScript = ./update.sh;
    };
  };
in
fhs

