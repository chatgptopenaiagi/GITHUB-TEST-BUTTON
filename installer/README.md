# Windows installer

`GTB.iss` packages the complete Flutter release directory. Run `scripts/Build-Windows.ps1` from PowerShell 7 after installing Flutter, Visual Studio C++ tools, and Inno Setup 6 or 7. Override discovery with `-InnoCompiler` and `-VcRuntimeDirectory` when necessary.

The installer uses a per-user installation, creates a Start Menu entry, and registers a normal uninstaller. It does not change Git, GitHub, Codex, network settings, or global authentication. Microsoft Visual C++ runtime DLLs are copied from the installed Visual Studio redistributable directory into the application bundle. Flutter data, plugin DLLs and compiled Dart code remain alongside the executable.

GTB's initial installer is not Authenticode signed. A Windows certificate is separate from the Android signing key. Build success alone does not establish clean-machine compatibility; consult the version-specific Windows build and functional test reports.
