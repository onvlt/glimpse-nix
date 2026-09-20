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
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "glimpse";
  version = "0.15.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "alex-oleshkevich";
    repo = "glimpse";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wiA7I0FwCTGnHnEEJOcuAtkCodTSsR9BIpmH56hwoQM=";
  };

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
  ]
  ++ lib.optionals stdenv.isLinux [
    wayland
  ];

  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Wayland desktop toolkit for Niri: panel, wallpaper, lock screen, night light, and other";
    homepage = "https://github.com/alex-oleshkevich/glimpse";
    changelog = "https://github.com/alex-oleshkevich/glimpse/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "glimpse";
  };
})
