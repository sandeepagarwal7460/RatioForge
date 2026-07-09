# Release Checklist

Use this checklist before creating and pushing a release tag.

## Versioning

- [ ] Decide the next SemVer version.
- [ ] Update `version.txt`.
- [ ] Update `Website/version.html`.
- [ ] Update `Source/Directory.Build.props`.
- [ ] Update version assertions in tests.
- [ ] Update `CHANGELOG.md` with the release date and notable changes.
- [ ] Update `README.md` if the current release highlights changed.

## Local Verification

- [ ] Confirm the worktree is clean before starting release edits.
- [ ] Run `dotnet restore Source\RatioForge.sln`.
- [ ] Run `dotnet build Source\RatioForge.sln --configuration Release --no-restore`.
- [ ] Run `dotnet test Source\RatioForge.sln --configuration Release --no-build`.
- [ ] Run `dotnet publish Source\RatioForge\RatioForge.csproj --configuration Release --runtime win-x64 --self-contained false --output artifacts\RatioForge-<version>-win-x64`.
- [ ] Confirm `artifacts\RatioForge-<version>-win-x64\RatioForge.exe` exists.
- [ ] Confirm `RatioForge.exe` file version matches `<version>.0`.
- [ ] Generate and verify SHA256 checksums for the zip archive and raw GUI executable.
- [ ] Remove local generated `artifacts\` output before committing.

## PyInstaller Status

- [ ] Confirm whether the repository contains a Python entry point (`.py`, `.spec`, or `pyproject.toml`).
- [ ] If a Python GUI or CLI target exists, build it with PyInstaller and add it to the release assets.
- [ ] If no Python entry point exists, do not create a PyInstaller release asset. Current RatioForge is a .NET Windows Forms application, so the release executable is built with `dotnet publish`.

## Commit And Tag

- [ ] Verify Git identity is `tsautier <tsautier@users.noreply.github.com>`.
- [ ] Commit release changes with author `tsautier <tsautier@users.noreply.github.com>`.
- [ ] Create an annotated tag: `git tag -a v<version> -m "RatioForge <version>"`.
- [ ] Push `master`.
- [ ] Push the tag: `git push origin v<version>`.

## GitHub Actions Verification

- [ ] Confirm the Build workflow passes.
- [ ] Confirm the Release workflow passes.
- [ ] Confirm the release page exists.
- [ ] Confirm these release assets exist and are non-empty:
  - `RatioForge-<version>-win-x64.zip`
  - `RatioForge-<version>-win-x64.exe`
  - `RatioForge-<version>-win-x64.sha256`
- [ ] Confirm the checksum file includes both the zip archive and raw GUI executable.
- [ ] Confirm no CLI executable is expected unless a dedicated CLI project exists.

## Rollback

- [ ] If the tag was pushed but release validation failed, delete the GitHub release first.
- [ ] Delete the remote tag: `git push origin :refs/tags/v<version>`.
- [ ] Delete the local tag: `git tag -d v<version>`.
- [ ] Revert or fix the release commit on `master`.
- [ ] Re-run local verification before tagging again.
