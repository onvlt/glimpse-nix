{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  blueprint-compiler,
  cairo,
  gdk-pixbuf,
  glib,
  gtk4,
  gtk4-layer-shell,
  libadwaita,
  libheif,
  pango,
  pipewire,
  stdenv,
  wayland,
  nix-update-script,
  pam,
  geoclue2,
  symlinkJoin,
}:

let
  pname = "glimpse";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "alex-oleshkevich";
    repo = "glimpse";
    tag = "v${version}";
    hash = "sha256-wiA7I0FwCTGnHnEEJOcuAtkCodTSsR9BIpmH56hwoQM=";
  };

  # The shell/lock/wallpaper binaries resolve packaged resources (theme packs,
  # applets, applet templates, idle monitor helper) from a hardcoded
  # /usr/share/glimpse prefix. Rewrite it to the store output so the package is
  # self-contained and does not depend on absolute host paths.
  patchResourcePaths = ''
    for file in $(grep -rl -e '/usr/share/glimpse' --include='*.rs' --include='*.toml' .); do
      substituteInPlace "$file" \
        --replace-fail "/usr/share/glimpse" "${placeholder "out"}/share/glimpse"
    done
  '';

  core = rustPlatform.buildRustPackage {
    pname = "glimpse";
    inherit version src;
    __structuredAttrs = true;

    cargoHash = "sha256-DerEnfzgmlT2NHCnQ1ZYbyWtOoLni0NZP8RsJm9Kff8=";

    nativeBuildInputs = [
      blueprint-compiler
      pkg-config
      rustPlatform.bindgenHook
      wrapGAppsHook4
    ];

    buildInputs = [
      cairo
      gdk-pixbuf
      glib
      gtk4
      gtk4-layer-shell
      libadwaita
      libheif
      pango
      pipewire
      pam
      geoclue2
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      wayland
    ];

    postPatch = patchResourcePaths;

    doCheck = false;

    doInstallCheck = true;
    installCheckPhase = ''
      for bin in glimpse-lock glimpse-shell glimpse-wallpaper; do
        test "$($out/bin/$bin --version)" = "$bin ${version}"
      done
    '';

    postInstall = ''
      # systemd user units
      install -Dm644 data/glimpse-shell.service $out/lib/systemd/user/glimpse-shell.service
      install -Dm644 data/glimpse-wallpaper.service $out/lib/systemd/user/glimpse-wallpaper.service
      install -Dm644 data/glimpse-lock.service $out/lib/systemd/user/glimpse-lock.service
      substituteInPlace $out/lib/systemd/user/glimpse-shell.service \
        --replace-fail "/usr/bin/glimpse-shell" "$out/bin/glimpse-shell"
      substituteInPlace $out/lib/systemd/user/glimpse-wallpaper.service \
        --replace-fail "/usr/bin/glimpse-wallpaper" "$out/bin/glimpse-wallpaper"
      substituteInPlace $out/lib/systemd/user/glimpse-lock.service \
        --replace-fail "/usr/bin/glimpse-lock" "$out/bin/glimpse-lock"

      # PAM service for glimpse-lock
      install -Dm644 data/pam.d/glimpse-lock $out/etc/pam.d/glimpse-lock

      # GeoClue config granting glimpse-shell location access
      install -Dm644 data/geoclue/glimpse.conf $out/etc/geoclue/conf.d/glimpse.conf

      # xdg-desktop-portal backend descriptor + D-Bus service activation
      install -Dm644 data/portals/glimpse.portal $out/share/xdg-desktop-portal/portals/glimpse.portal
      install -Dm644 data/dbus-1/me.aresa.GlimpseIdle.Portal.service $out/share/dbus-1/services/me.aresa.GlimpseIdle.Portal.service
      substituteInPlace $out/share/dbus-1/services/me.aresa.GlimpseIdle.Portal.service \
        --replace-fail "/usr/bin/glimpse-shell" "$out/bin/glimpse-shell"

      # monitor helper used by the default idle config
      install -Dm755 data/scripts/monitors $out/share/glimpse/scripts/monitors

      # bundled theme packs
      for pack in rosepine edgeglass; do
        if [[ -d themes/$pack ]]; then
          install -d $out/share/glimpse/themes/$pack
          install -m644 themes/$pack/* $out/share/glimpse/themes/$pack/
        fi
      done

      # applet project templates read by `glimpse-shell applets new`
      mkdir -p $out/share/glimpse/applet-templates
      cp -r applet-templates/. $out/share/glimpse/applet-templates/

      # license
      install -Dm644 LICENSE $out/share/licenses/glimpse/LICENSE
    '';

    passthru.updateScript = nix-update-script { };
  };

  # Applet packages are standalone Cargo workspaces (each with its own
  # Cargo.lock and a path dependency on sdk/sdk-rs), so they are built as
  # separate derivations and installed into the system applet directory.
  appletHashes = {
    colorpicker = "sha256-NThgRGNPeNBMzXTHvikbV/SLu0hBDTUmUyZ7orxnJUQ=";
    kdeconnect = "sha256-ISKKAX9V9KfrA+M0f6W6/FXEA7SBvPK4PBwlKpGGnwU=";
    sysmonitor = "sha256-HUEcLu/CGcDYkaBmDW4PAUBwfl9JQB2KnnBDtxKDLbI=";
  };

  buildGlimpseApplet =
    appletName:
    rustPlatform.buildRustPackage {
      pname = "glimpse-${appletName}-applet";
      inherit version src;

      cargoRoot = "glimpse-applets/${appletName}";
      buildAndTestSubdir = "glimpse-applets/${appletName}";
      cargoHash = appletHashes.${appletName};

      postPatch = patchResourcePaths;

      doCheck = false;

      installPhase = ''
        runHook preInstall
        install -Dm755 target/${stdenv.targetPlatform.rust.cargoShortTarget}/release/${appletName} $out/share/glimpse/applets/${appletName}/${appletName}
        install -Dm644 glimpse-applets/${appletName}/applet.toml $out/share/glimpse/applets/${appletName}/applet.toml
        runHook postInstall
      '';
    };

  appletNames = builtins.attrNames appletHashes;
  applets = map buildGlimpseApplet appletNames;
in
symlinkJoin {
  name = "${pname}-${version}";
  paths = [ core ] ++ applets;

  passthru = {
    inherit core applets;
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Wayland desktop toolkit for Niri: panel, wallpaper, lock screen, night light, and other";
    homepage = "https://github.com/alex-oleshkevich/glimpse";
    changelog = "https://github.com/alex-oleshkevich/glimpse/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "glimpse-shell";
  };
}
