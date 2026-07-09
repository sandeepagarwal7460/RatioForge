# Roadmap

This roadmap is intentionally practical: it separates near-term maintenance from larger product and architecture work.

## Short Term

- Harden GitHub Actions release automation with asset verification, checksums, and repeatable smoke checks.
- Keep NuGet dependencies current and verify release builds on every tagged version.
- Expand tests around version checking, torrent parsing, and tracker URL generation.
- Document release, rollback, and verification steps so releases are reproducible.
- Review legacy website pages and remove obsolete links or stale historical calls to action.

## Mid Term

- Add a dedicated CLI project if command-line automation is needed.
- Add structured logging for tracker communication, version checks, and proxy failures.
- Improve error handling around network, proxy, and malformed torrent files.
- Add sample torrent fixtures for parser and tracker behavior tests.
- Evaluate self-contained Windows publishing for users without a local .NET runtime.
- Add a signed release path if code-signing certificates become available.

## Long Term

- Separate core torrent/tracker logic from Windows Forms UI into reusable libraries.
- Consider a modern UI refresh while preserving the existing lightweight workflow.
- Add a documented plugin or profile system for torrent client emulation data.
- Build a CLI executable and, only if a Python entry point is introduced, add a PyInstaller-based Windows executable pipeline.
- Add automated compatibility testing across supported Windows runner images.
- Define a security and disclosure policy for tracker, proxy, and release-distribution issues.
