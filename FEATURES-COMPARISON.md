# Lite vs full GodotSaveKit

Lite is a smaller functional subset with an original implementation, not copied paid-kit code. This table describes inspected full-kit implementation files, not a verification of storefront contents. **Licences differ.** GodotSaveKit Lite is MIT-licensed: see the `LICENSE` file in this repository. The full GodotSaveKit is sold under a single-developer commercial licence (Fortress MSSP LLC) and is **not** MIT; its licence terms are supplied with the purchase.

Full-source citations below are workspace-relative provenance references, not links to a public repository. They were re-checked against implementation files; functions are named so citations remain useful if lines shift.

| Feature | Lite | Full kit | Full-kit source |
| --- | --- | --- | --- |
| Dictionary JSON persistence / slots | One fixed version-1 file | Named slots with versioned envelopes | `gsk_project/addons/godot_save_kit/save_manager.gd`, `_valid_id`, `_path`, `save_slot` (lines 27–33, 65–77) |
| Atomic-style write / replacement | Validated same-directory temp + rename | Temp write, flush, validate, backup and rename | `gsk_project/addons/godot_save_kit/json_store.gd`, `write_json` (40–67); no portable directory fsync (line 2) |
| `.bak` recovery | None | Backs up a valid old primary; tries primary then `.bak` on load, subject to error/version guards | `gsk_project/addons/godot_save_kit/json_store.gd`, `write_json` (56–63); `save_manager.gd`, `_load` (92–116) |
| Corrupt-file quarantine | None; load leaves file untouched | Moves invalid files into quarantine | `gsk_project/addons/godot_save_kit/save_manager.gd`, `_load` (98–102); `json_store.gd`, `quarantine` (69–76) |
| Migration hook | None | Registered stepwise Callable migrations; caller supplies conversions | `gsk_project/addons/godot_save_kit/save_manager.gd`, `register_migration`, `unregister_migration` (48–54), `_load` (108–114) |
| Autosave | None | Timer plus caller snapshot provider | `gsk_project/addons/godot_save_kit/save_manager.gd`, `start_autosave` through `request_autosave` (161–194) |
| Slot metadata / listing | None | Timestamp, caller playtime and screenshot path; sorted slot listing (not screenshot capture) | `gsk_project/addons/godot_save_kit/save_manager.gd`, `save_slot` (72), `list_slots` (118–141) |
| Settings service | None | Audio bus volume, window mode/resolution, vsync and action-event persistence/application | `gsk_project/addons/godot_save_kit/settings_service.gd`, `set_audio_bus_volume_db` through `apply_settings` (121–167); window calls skipped when headless |
| Input rebinding | None | Capture, cancellation and conflict queries; caller feeds events | `gsk_project/addons/godot_save_kit/input_rebinding.gd`, `begin_capture`, `cancel_capture`, `feed_event`, `find_conflicts` (10–56) |
| Test evidence | 26 Lite checks, 0 failures in final build rerun | 73 checks, 0 failures, not 73 separate test files | `gsk_project/addons/godot_save_kit/tests/run.gd`, runner/counter; `tests/test_settings.gd` in the same addon and `gsk_project/tests/test_save.gd`; recorded result/count reconciliation: `GodotSaveKit_TEST_REPORT.md:7,125,140` |
| License | MIT (see this repository's `LICENSE`) | Single-developer commercial licence (Fortress MSSP LLC); not MIT | Licence terms supplied with the full kit purchase |

Lite evidence: `test_output_v1.0.1.txt`, final rerun, 26 checks / 0 failures. Full evidence: `GodotSaveKit_TEST_REPORT.md` and `GodotSaveKit_LAUNCH-SHEET.md:35–50`. Both recorded test scopes are **Godot 4.7.2 stable, headless macOS only**; neither table nor counts imply GUI, power-loss, export or cross-platform testing. The full suite is not inherited by Lite. Neither kit's rename-based replacement is a power-loss durability guarantee.

Full paid kit: https://mustafawave286.gumroad.com/l/ucpdfx?utm_source=godot_asset_library&utm_medium=free_addon&utm_campaign=savekit_lite
