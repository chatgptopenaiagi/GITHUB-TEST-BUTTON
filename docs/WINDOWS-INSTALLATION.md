# Windows installation

GTB targets Windows x64. Download `GTB-Windows-Setup.exe` from the project's release assets and compare its SHA-256 with `SHA256SUMS.txt`. Run the installer and launch **GITHUB TEST BUTTON** from the Start menu. The installer provides normal uninstall registration. Python is not required for the GUI.

For portable use, extract **all** of `GTB-Windows-Portable.zip` into one directory and run `github_test_button.exe`. Keep its DLLs and `data` directory together. The distribution includes Flutter support files and app-local Microsoft C++ runtime libraries.

The first button performs public read-only diagnostics. GitHub CLI, Git, PowerShell and Codex are optional capabilities; absence of Codex never prevents testing GitHub. Existing GitHub CLI authentication can provide the signed-in account. The repository panel accepts `OWNER/REPOSITORY`.

Initial builds are a beta and the installer is not Authenticode-signed unless the release verification explicitly says otherwise. Follow your organization's software installation policy. Development-machine tests do not establish clean-machine compatibility; consult the platform report for actual coverage.
