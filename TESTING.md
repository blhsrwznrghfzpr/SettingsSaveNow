# In-game verification

Automated checks do not launch Resonite. Run these checks separately with each loader, using a test profile.

1. Install the RML or Bepis build, start Resonite, and check the log for `SettingsSaveNow loaded.`.
2. Open Dashboard > Settings. Confirm one save button appears at the top of the category list.
3. Switch categories, search, close/reopen the dashboard, and open another settings facet. Confirm the button remains usable and does not duplicate.
4. Change a harmless setting (for example an audio volume), press Save, and confirm progress followed by completion and a log entry.
5. Type a new value into a setting text field and click Save while it still has focus. Confirm the committed value is saved.
6. Click rapidly, including in another settings facet. Confirm only one save runs at a time. Change categories or close the dashboard during the save; the operation should finish.
7. Test both logged-in and logged-out sessions. Offline saves should use the normal local queue; do not interpret completion as proof of a cloud upload.
8. In a disposable test session, verify persistence across a restart that does not run normal exit saves. Normal exit itself saves settings and therefore cannot prove this mod performed the save.
9. Launch with `-NeverSaveSettings`; press the button and confirm it reports saving is disabled without saving.
10. With a controlled storage failure in a disposable environment, confirm exceptions appear in the log, the button reports failure, and retry remains possible.
11. Test Japanese and English UI labels.
12. In a fresh Gale profile, import the Gale ZIP, confirm dependencies and plugin installation, then enable/disable/remove it and verify the plugin follows the profile state.

The SDK reference version is 2026.8.27.1094. Repeat these checks on the Resonite version used for a release. The mod delegates record-save and sync behavior to Resonite; engine-internal failures not surfaced as exceptions follow the engine's normal behavior.
