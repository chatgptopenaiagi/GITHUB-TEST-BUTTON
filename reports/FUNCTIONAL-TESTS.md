# Functional tests

Final local results: **111 distinct automated tests passed,0 failed** (61 Python methods and50 Flutter tests, including8 widget tests). Repeated runs and CI matrix executions are not counted as additional distinct tests.

| Independent acceptance scope | Passed | Evidence |
|---|---:|---|
| Installed Python wheel |10|python-wheel-verification.json|
| Installed Windows GUI |10|windows-runtime.json|
| Windows installer lifecycle |4|windows-runtime.json|
| Signed universal APK on Android emulator |12|android-runtime.json|
| Live report JSON schema validation |4|contract-validation.json|

Real existing-repository write verification created branch `gtb-verify-4adb26cb1285`, commit `1a02583cc866df5d81e281456526c79f321dbc22`, containing only generated verification content. The installed CLI verified content and commit through the API; an independent GitHub CLI readback matched. Final-wheel resume reread the remote content without another push. Evidence: real-write-test.json, independent-write-readback.json, final-wheel-write-readback.json.

The Windows GUI displayed measured API/HTTPS results and authenticated identity, exported valid JSON/TXT, changed appearance/language and retained settings/history after restart. Installation and normal uninstall both succeeded on the development host. Windows GUI repository text-entry automation remains unverified, as recorded in limitations.

The Android universal APK launched on API37 x86_64, ran real public diagnostics and product-repository lookup, correctly separated unsupported desktop tools, retained settings and exposed native sharing. The JSON share payload was extracted and parsed without transmission. Private-file export checks used the application's save acknowledgement; those private files were not separately pulled.

Static Flutter analysis reports no issues. Hosted Python CI passes all four Windows/Ubuntu and Python3.10/3.13 combinations. Hosted Windows/Android build status is captured separately; failed historical attempts are retained and not relabeled as successes.

This evidence does not establish physical ARM64 operation, clean-machine Windows compatibility, mobile OAuth, or every network environment. See KNOWN-LIMITATIONS.md.

All three hosted workflows for runtime source commit a1ee1d8428e1cc2159795078a977942442bffeac completed successfully: Windows43727124084, Android43727124028, Python43727124040. Receipt: ci-platform-current.json. Later release-evidence changes do not alter the application sources.
