# Time zone data in Nintendo Switch (RFC 8536) format, needed at build time via
# YUZU_TZDB_PATH. This is the same helper nixpkgs ships for the eden package.
{
  stdenv,
  lib,
  fetchFromGitea,
  cmake,
  ninja,
  tzdata,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tzdb_to_nx";
  version = "230326";

  src = fetchFromGitea {
    domain = "git.eden-emu.dev";
    owner = "eden-emu";
    repo = "tzdb_to_nx";
    tag = finalAttrs.version;
    hash = "sha256-koz7C63oHVfrhrf9lfdUqw6idJWi21XRKQnb5PdoEb4=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  cmakeFlags = [
    (lib.cmakeFeature "TZDB2NX_ZONEINFO_DIR" "${tzdata}/share/zoneinfo")
    (lib.cmakeFeature "TZDB2NX_VERSION" tzdata.version)
  ];

  ninjaFlags = [ "x80e" ];

  installPhase = ''
    runHook preInstall

    cp -r src/tzdb/nx $out

    runHook postInstall
  '';

  meta = {
    description = "RFC 8536 time zone data converted to the Nintendo Switch format";
    license = [
      lib.licenses.mit # Converter
      lib.licenses.publicDomain # Data
    ];
    platforms = lib.platforms.all;
  };
})
