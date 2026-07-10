# Roadmap

This roadmap is intentionally practical: it separates near-term maintenance from larger product and architecture work.

## Short Term

- Harden GitHub Actions release automation with asset verification, checksums, and repeatable smoke checks.
- Keep NuGet dependencies current and verify release builds on every tagged version.
- Extend the existing torrent parsing and tracker URL tests with additional malformed and edge-case fixtures.
- Document release, rollback, and verification steps so releases are reproducible.
- Decide whether the refreshed legacy website should remain maintained or be replaced by GitHub Pages.

## Mid Term

- Add a dedicated .NET CLI project if command-line automation is needed.
- Add structured logging for tracker communication, version checks, and proxy failures.
- Improve error handling around network, proxy, and malformed torrent files.
- Add sample torrent fixtures for parser and tracker behavior tests.
- Monitor self-contained single-file release size and startup behavior.
- Add a signed release path if code-signing certificates become available.

## Long Term

- Move the extracted tracker URL builder and torrent parser into a dedicated reusable core library.
- Consider a modern UI refresh while preserving the existing lightweight workflow.
- Add a documented plugin or profile system for torrent client emulation data.
- Build a dedicated .NET CLI executable if command-line workflows become part of the product.
- Add automated compatibility testing across supported Windows runner images.
- Define a security and disclosure policy for tracker, proxy, and release-distribution issues.
