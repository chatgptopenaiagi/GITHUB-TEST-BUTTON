# Implemented product architecture

Flutter/Dart implements shared Windows and Android presentation and native networking. Python implements a separate portable CLI. Both conform to the shared report schema and diagnostic classifier fixtures; they do not share an executable runtime.

The graphical application offers connection testing, repository lookup, details/export, history and local preferences. Windows delegates optional identity/tool queries to installed tools. Android public diagnostics operate independently; local Git write engineering is explicitly unsupported there. The CLI implements guarded, resumable repository write tests; the desktop GUI supplies an explicit separate write action.

See [architecture](../docs/ARCHITECTURE.md) and the actual source under `flutter/lib` and `python/src`. Packaging scripts produce complete Windows runtime bundles, a signed Android release and pure Python distributions. No cloud diagnostic backend is needed. Mobile OAuth registration/integration remains pending.
