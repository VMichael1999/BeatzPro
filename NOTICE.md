# Avisos y procedencia

Este documento declara quién es el autor de cada parte de BeatzPro y qué material proviene
de terceros. Está pensado para cumplir la licencia GNU GPL v3 y para que cualquiera pueda
comprobar el origen del código.

> **Resumen:** BeatzPro **no** es obra de un único autor. Contiene código de terceros bajo
> GPL v3 (aviso original: *Copyright © 2024 anandnet*, y colaboradores), traducciones de una
> comunidad de traductores e imágenes de terceros. Las partes propias se detallan abajo.

## 1. BeatzPro

Copyright © 2026 Michael Valdiviezo, para las contribuciones propias descritas en la sección 3.

BeatzPro es software libre: puedes redistribuirlo y modificarlo bajo los términos de la
**GNU General Public License v3** publicada por la Free Software Foundation. El texto
completo está en [LICENSE](LICENSE). Se distribuye sin ninguna garantía.

El proyecto como conjunto es una obra derivada de código GPL v3 y por eso **debe seguir
distribuyéndose bajo GPL v3**.

## 2. Código de terceros

| Titular del copyright | Material | Licencia |
| --- | --- | --- |
| anandnet (Anand Kumar) y colaboradores | Base del código de la aplicación en `lib/` (modelos, servicios, controladores, widgets) | GPL v3 |
| Comunidad de traductores | Archivos de traducción en `localization/` (44 idiomas) y el archivo generado `lib/utils/get_localization.dart` | GPL v3 |
| anandnet | Iconos `assets/icons/album.png`, `artist.png` y `song.png` | GPL v3 |

Los avisos de copyright originales se conservan tal cual (`macos/Runner/Configs/AppInfo.xcconfig`
y `windows/runner/Runner.rc`) y no deben eliminarse.

## 3. Contribución propia (Michael Valdiviezo)

- Rediseño completo de la interfaz «Onda»: sistema de color y tokens, tema dinámico por
  carátula, reproductor, cola, letra, relacionado, mini reproductor, temporizador, inicio,
  búsqueda, álbum y lista, barra inferior.
- Componentes nuevos: onda de progreso, indicador «sonando», iconos, filas de canciones,
  tinte de carátula.
- Reproducción por el cliente `VISIONOS` de YouTube (`lib/services/visionos_stream.dart`) y
  adaptación a los cambios recientes de YouTube (búsqueda, charts, parser de álbumes).
- Compilación para iOS y ajustes del proyecto.

### 3.1 Archivos nuevos creados en este proyecto (10 archivos, 1407 líneas)

| Archivo | Líneas |
| --- | ---: |
| `lib/services/visionos_stream.dart` | 142 |
| `lib/services/yt_auth.dart` | 69 |
| `lib/ui/screens/Settings/youtube_login_screen.dart` | 81 |
| `lib/ui/utils/beatz_design.dart` | 154 |
| `lib/ui/utils/beatz_icon_data.dart` | 39 |
| `lib/ui/widgets/beatz/beatz_icon.dart` | 107 |
| `lib/ui/widgets/beatz/beatz_widgets.dart` | 479 |
| `lib/ui/widgets/beatz/cover_tint.dart` | 94 |
| `lib/ui/widgets/beatz/eq_bars.dart` | 95 |
| `lib/ui/widgets/beatz/wave_progress.dart` | 147 |

### 3.2 Archivos reescritos casi por completo (16 archivos, 4808 líneas)

La columna indica cuánto del texto coincide con la versión más parecida del código de
terceros; un valor bajo significa que el archivo es mayormente propio.

| Archivo | Líneas | Coincidencia con el original |
| --- | ---: | ---: |
| `lib/ui/player/player.dart` | 1224 | 4 % |
| `lib/ui/player/mini_player.dart` | 377 | 9 % |
| `lib/ui/screens/PlaylistNAlbum/playlistnalbum_screen.dart` | 554 | 11 % |
| `lib/ui/widgets/sleep_timer_bottom_sheet.dart` | 272 | 13 % |
| `lib/ui/screens/Search/search_result_screen_v2.dart` | 149 | 17 % |
| `lib/ui/screens/Search/search_screen.dart` | 131 | 20 % |
| `lib/ui/widgets/bottom_nav_bar.dart` | 81 | 22 % |
| `lib/ui/widgets/quickpickswidget.dart` | 87 | 29 % |
| `lib/ui/widgets/shimmer_widgets/home_shimmer.dart` | 88 | 30 % |
| `lib/ui/widgets/content_list_widget_item.dart` | 132 | 31 % |
| `lib/ui/screens/Settings/settings_screen.dart` | 725 | 32 % |
| `lib/ui/widgets/content_list_widget.dart` | 68 | 35 % |
| `lib/services/stream_service.dart` | 196 | 41 % |
| `lib/ui/widgets/search_related_widgets.dart` | 178 | 41 % |
| `lib/ui/widgets/list_widget.dart` | 298 | 43 % |
| `lib/ui/utils/theme_controller.dart` | 248 | 45 % |

### 3.3 Archivos nuevos cuya autoría debe confirmar el titular (5 archivos, 600 líneas)

No existen en el código de terceros, pero este análisis automático no puede demostrar quién
los escribió.

| Archivo | Líneas |
| --- | ---: |
| `lib/ui/screens/Home/splash_screen.dart` | 59 |
| `lib/ui/widgets/button_play.dart` | 154 |
| `lib/ui/widgets/buttonplay_animation.dart` | 152 |
| `lib/ui/widgets/custom_lyricui.dart` | 86 |
| `lib/ui/widgets/custom_progress.dart` | 149 |

## 4. Archivos basados en código de terceros, con cambios propios (38 archivos, 9255 líneas)

Conservan el aviso de copyright original; la columna indica cuánto coincide con el original.

| Archivo | Líneas | Coincidencia con el original |
| --- | ---: | ---: |
| `lib/ui/screens/Artists/artist_screen_controller.dart` | 276 | 100 % |
| `lib/services/nav_parser.dart` | 1087 | 99 % |
| `lib/services/utils.dart` | 218 | 99 % |
| `lib/services/windows_audio_service.dart` | 92 | 99 % |
| `lib/ui/screens/Artists/artist_screen.dart` | 292 | 99 % |
| `lib/ui/widgets/backup_dialog.dart` | 170 | 99 % |
| `lib/ui/widgets/export_file_dialog.dart` | 156 | 99 % |
| `lib/ui/widgets/restore_dialog.dart` | 155 | 99 % |
| `lib/ui/widgets/side_nav_bar.dart` | 124 | 99 % |
| `lib/ui/widgets/new_version_dialog.dart` | 80 | 98 % |
| `lib/ui/widgets/piped_sync_widget.dart` | 48 | 98 % |
| `lib/ui/widgets/song_download_btn.dart` | 89 | 98 % |
| `lib/utils/helper.dart` | 191 | 98 % |
| `lib/utils/system_tray.dart` | 125 | 98 % |
| `lib/services/continuations.dart` | 192 | 97 % |
| `lib/services/synced_lyrics_service.dart` | 37 | 97 % |
| `lib/ui/widgets/cust_switch.dart` | 25 | 96 % |
| `lib/ui/widgets/sort_widget.dart` | 382 | 94 % |
| `lib/ui/widgets/up_next_queue.dart` | 138 | 93 % |
| `lib/ui/screens/Search/search_result_screen_controller.dart` | 202 | 92 % |
| `lib/ui/widgets/add_to_playlist.dart` | 220 | 92 % |
| `lib/main.dart` | 127 | 91 % |
| `lib/services/music_service.dart` | 1047 | 90 % |
| `lib/ui/navigator.dart` | 55 | 89 % |
| `lib/ui/widgets/separate_tab_item_widget.dart` | 129 | 88 % |
| `lib/ui/screens/Library/library.dart` | 264 | 86 % |
| `lib/ui/screens/Settings/settings_screen_controller.dart` | 275 | 85 % |
| `lib/models/media_Item_builder.dart` | 96 | 84 % |
| `lib/ui/home.dart` | 151 | 82 % |
| `lib/ui/screens/Home/home_screen_controller.dart` | 373 | 81 % |
| `lib/ui/widgets/image_widget.dart` | 134 | 81 % |
| `lib/ui/player/player_controller.dart` | 748 | 78 % |
| `lib/services/constant.dart` | 7 | 77 % |
| `lib/services/downloader.dart` | 257 | 77 % |
| `lib/services/background_task.dart` | 54 | 74 % |
| `lib/models/streaming_data.dart` | 70 | 64 % |
| `lib/services/audio_handler.dart` | 840 | 62 % |
| `lib/ui/screens/Home/home_screen.dart` | 329 | 54 % |

## 5. Archivos de terceros sin modificar (32 archivos, 3921 líneas)

| Archivo | Líneas |
| --- | ---: |
| `lib/models/album.dart` | 58 |
| `lib/models/artist.dart` | 43 |
| `lib/models/durationstate.dart` | 7 |
| `lib/models/playlist.dart` | 63 |
| `lib/models/quick_picks.dart` | 8 |
| `lib/models/thumbnail.dart` | 12 |
| `lib/services/permission_service.dart` | 34 |
| `lib/services/piped_service.dart` | 186 |
| `lib/ui/screens/Artists/artist_screen_v2.dart` | 102 |
| `lib/ui/screens/Library/library_combined.dart` | 102 |
| `lib/ui/screens/Library/library_controller.dart` | 534 |
| `lib/ui/screens/PlaylistNAlbum/playlistnalbum_screen_controller.dart` | 335 |
| `lib/ui/screens/Search/search_result_screen.dart` | 158 |
| `lib/ui/screens/Search/search_screen_controller.dart` | 69 |
| `lib/ui/widgets/animated_screen_transition.dart` | 58 |
| `lib/ui/widgets/common_dialog_widget.dart` | 20 |
| `lib/ui/widgets/create_playlist_dialog.dart` | 177 |
| `lib/ui/widgets/link_piped.dart` | 190 |
| `lib/ui/widgets/loader.dart` | 20 |
| `lib/ui/widgets/marqwee_widget.dart` | 65 |
| `lib/ui/widgets/mini_player_progress_bar.dart` | 50 |
| `lib/ui/widgets/modification_list.dart` | 126 |
| `lib/ui/widgets/scroll_to_hide.dart` | 18 |
| `lib/ui/widgets/shimmer_widgets/basic_container.dart` | 19 |
| `lib/ui/widgets/shimmer_widgets/song_list_shimmer.dart` | 34 |
| `lib/ui/widgets/sliding_up_panel.dart` | 777 |
| `lib/ui/widgets/snackbar.dart` | 34 |
| `lib/ui/widgets/songinfo_bottom_sheet.dart` | 423 |
| `lib/utils/app_link_controller.dart` | 123 |
| `lib/utils/house_keeping.dart` | 25 |
| `lib/utils/lang_mapping.dart` | 46 |
| `lib/utils/update_check_flag_file.dart` | 5 |

## 6. Tipografías, iconos y servicios

| Material | Titular / fuente | Licencia |
| --- | --- | --- |
| Nunito Sans y Acme (tipografías, vía `google_fonts`) | Autores de las fuentes, publicadas en Google Fonts | SIL Open Font License 1.1 |
| Icono de ajustes (tuerca) | [Feather Icons](https://feathericons.com), Copyright © 2013-2017 Cole Bemis | MIT |
| Letras sincronizadas | Servicio [lrclib.net](https://lrclib.net) | Según el servicio |
| Carátulas y contenido de audio | YouTube Music y sus autores. BeatzPro no los aloja ni está afiliado a YouTube o Google | Según sus titulares |

## 7. Dependencias

Paquetes directos de `pubspec.yaml` y su licencia (comprobada en el código de cada paquete).

| Licencia | Paquetes |
| --- | --- |
| MIT | audio_service, audio_video_progress_bar, get, dio, cached_network_image, flutter_svg, flutter_keyboard_visibility, permission_handler, sdk_int, file_picker, audiotags, toggle_switch, buttons_tabbar, sidebar_with_animation, window_manager, smtc_windows, audio_service_mpris, ionicons, archive, tray_manager, mini_music_visualizer, just_waveform, newton_particles, particular, particle_forked, carousel_animations, music_visualizer |
| BSD-3-Clause | video_player, youtube_explode_dart, crypto, http, palette_generator, path_provider, shimmer, url_launcher, share_plus, google_fonts, flutter_lyric, animations, path, simple_ripple_animation |
| Apache-2.0 | just_audio, flutter_inappwebview, hive, hive_flutter, app_links, text_neon_widget |
| Dominio público (Unlicense) | just_audio_media_kit |
| **Sin licencia declarada** | device_equalizer (su `LICENSE` dice «TODO: Add your license here») |

## 8. Puntos pendientes de resolver

1. **`device_equalizer`** no declara licencia: por defecto todos los derechos están
   reservados. Conviene pedirle al autor que la añada o sustituir el paquete.
2. Se eliminaron las imágenes de `fastlane/metadata/android/en-US/images/` (capturas e icono),
   que eran del proyecto original. Conviene agregar capturas propias de BeatzPro.
3. Confirmar la **autoría de los iconos y logos propios** (`assets/icons/app_ic.png`,
   `ico.png`, `icon.png`, `ic_music.png`, `icon_music.png`) y de los archivos de la
   sección 3.3.
4. Cada archivo nuevo puede llevar una cabecera `Copyright © 2026 Michael Valdiviezo` y la
   referencia a la licencia.

_Las cifras de este documento se calcularon comparando el repositorio con el historial del
código de terceros; son aproximadas._
