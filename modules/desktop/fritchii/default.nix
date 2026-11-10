# Lichii (Frizti fork) - Nintendo Switch emulator specialized for
# The Legend of Zelda: Ocarina of Time (Switch 2 "nx2" fork of eden/yuzu).
#
# Built from the commit the "Fritchii v5.6" release was built from, since the
# fork publishes Windows binaries only. Packaging follows nixpkgs' eden
# derivation: every CPM dependency comes from nixpkgs (CPMUtil finds system
# packages), except a few download-only assets which are pre-seeded into
# CPM's cache below.
{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  python3,
  glslang,
  fetchFromGitHub,
  qt6,
  kdePackages,
  wrapGAppsHook3,
  boost,
  cpp-jwt,
  cubeb,
  enet,
  ffmpeg-headless,
  fmt,
  frozen-containers,
  gamemode,
  httplib,
  libopus,
  libusb1,
  lz4,
  nlohmann_json,
  openssl,
  pipewire,
  sdl3,
  simpleini,
  sirit,
  spirv-headers,
  vulkan-headers,
  vulkan-loader,
  vulkan-memory-allocator,
  vulkan-utility-libraries,
  xbyak,
  zlib,
  zstd,
  callPackage,
}:

let
  nx_tzdb = callPackage ./nx_tzdb.nix { };

  # Download-only CPM assets, pre-seeded so the sandboxed configure step never
  # touches the network. Versions/hashes are pinned in cpmfile.json in the source.
  zbic-src = fetchFromGitHub {
    owner = "kinnay";
    repo = "zbic";
    rev = "11b08f2712264bbed731545085cbd9702096ceb7";
    hash = "sha256-pHvxa1gkUvQo6mUgmLWtj1kcu01BLdGmttZyb8ZAj/o=";
  };

  reshade-src = fetchFromGitHub {
    owner = "crosire";
    repo = "reshade";
    rev = "v6.8.0";
    hash = "sha256-K6QC7CLqy8M318n9WbuqGvcRF9g9abvDD/xbr7T+nXo=";
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "lichii-frizti";
  version = "5.6";

  src = fetchFromGitHub {
    owner = "Frizti";
    repo = "Fritchii";
    rev = "696a456641ae83c9f8b6564c57ac311c7ef56799";
    hash = "sha256-1Jnfd1qJDi3JMaRyVHQ8NydCv56CsOw71CulTJl5cQE=";
  };

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    cmake
    ninja
    glslang
    pkg-config
    python3
    qt6.qttools
    qt6.wrapQtAppsHook
    wrapGAppsHook3
  ];

  buildInputs = [
    boost
    cpp-jwt
    cubeb
    enet
    ffmpeg-headless
    fmt
    frozen-containers
    gamemode
    httplib
    kdePackages.quazip
    libopus
    libusb1
    # intentionally omitted: LLVM - heavy, only used for stack traces in the debugger
    lz4
    nlohmann_json
    openssl
    qt6.qtbase
    qt6.qtcharts
    qt6.qtwayland
    sdl3
    simpleini
    sirit
    spirv-headers
    vulkan-headers
    vulkan-loader
    vulkan-memory-allocator
    vulkan-utility-libraries
    xbyak
    zlib
    zstd
  ];

  cmakeFlags = [
    # Upstream Linux CI configuration (release-binaries.yml)
    (lib.cmakeBool "BUILD_TESTING" false)
    (lib.cmakeBool "YUZU_TESTS" false)
    (lib.cmakeBool "YUZU_CMD" true)
    (lib.cmakeBool "YUZU_ROOM" false)
    (lib.cmakeBool "YUZU_ROOM_STANDALONE" false)
    (lib.cmakeBool "YUZU_USE_BUNDLED_QT" false)
    (lib.cmakeBool "YUZU_USE_BUNDLED_SDL3" false)
    (lib.cmakeBool "ENABLE_UPDATE_CHECKER" true)
    (lib.cmakeBool "USE_DISCORD_PRESENCE" false)
    (lib.cmakeBool "ENABLE_RESHADE" true)

    # Use system libraries instead of CPM downloads. zstd/Opus are marked
    # bundled in cpmfile.json; force them to system.
    (lib.cmakeBool "zstd_FORCE_SYSTEM" true)
    (lib.cmakeBool "Opus_FORCE_SYSTEM" true)

    # Time zone data comes from the pinned nx_tzdb package
    (lib.cmakeFeature "YUZU_TZDB_PATH" "${nx_tzdb}")

    # GCC 16 hits new warnings that upstream CI (clang/gcc 15) never sees
    (lib.cmakeBool "ENABLE_WERROR" false)

    # dynarmic still uses the old FindBoost module
    "-DCMAKE_POLICY_DEFAULT_CMP0167=NEW"
  ];

  postPatch = ''
    # Pre-seed CPM's source cache for the two download-only assets so the
    # sandboxed configure step never touches the network. The layout must
    # match CPMUtil's get_cache_path(): .cache/cpm/<lower-name>/<version>/,
    # with a .cpm_patch_key file inside ("none" when unpatched, otherwise the
    # SHA512 of the concatenated patch contents). The key comparison is
    # exact, so the files must contain no trailing newline. Revisions must
    # match the versions pinned in cpmfile.json in the source.
    zbicDir=.cache/cpm/zbic/11b08f2712264bbed731545085cbd9702096ceb7
    mkdir -p "$zbicDir"
    cp -r ${zbic-src}/. "$zbicDir"/
    printf 'none' > "$zbicDir"/.cpm_patch_key

    reshadeDir=.cache/cpm/reshade/v6.8.0
    mkdir -p "$reshadeDir"
    cp -r ${reshade-src}/. "$reshadeDir"/
    chmod -R u+w "$reshadeDir"
    patch -p1 -d "$reshadeDir" < .patch/reshade/0001-from-chars-fallback.patch
    sha512sum .patch/reshade/0001-from-chars-fallback.patch | cut -d' ' -f1 | tr -d '\n' \
      > "$reshadeDir"/.cpm_patch_key

    # SCM-revision metadata (no .git tree in a Nix build)
    printf '%s\n' '696a456641ae83c9f8b6564c57ac311c7ef56799' > GIT-COMMIT
    printf 'nx2\n' > GIT-REFSPEC
    printf 'fritchii-v5.6\n' > GIT-TAG
    printf 'fritchii-v5.6\n' > GIT-RELEASE
  '';

  postInstall = ''
    install -Dm444 $src/dist/72-eden-input.rules $out/lib/udev/rules.d/72-eden-input.rules
  '';

  preFixup = ''
    qtWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          vulkan-loader
          pipewire
        ]
      }
    )
  '';

  meta = {
    description = "Switch 2 emulator specialized for Zelda: Ocarina of Time (Lichii Frizti fork)";
    homepage = "https://github.com/Frizti/Fritchii";
    mainProgram = "lichii";
    license = with lib.licenses; [
      # Primary (Lichii/yuzu lineage)
      gpl3Plus

      # Dynamic FPS add-on by Eglantine Dev (MIT) and other mixed content
      mit

      # Build system
      lgpl3Plus

      # Dynarmic and yuzu code
      gpl2Plus
      bsd0

      # Vendored/incorporated libs
      asl20
      lib.licenses.boost
      bsd2
      bsd3
      mit
      mpl20
      wtfpl
      cc-by-40
      cc-by-sa-30
      cc0
    ];
    platforms = [ "x86_64-linux" ];
  };
})
