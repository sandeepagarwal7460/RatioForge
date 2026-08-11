# RatioForge

[![Build RatioForge](https://github.com/tsautier/RatioForge/actions/workflows/build.yml/badge.svg)](https://github.com/tsautier/RatioForge/actions/workflows/build.yml)
[![Release RatioForge](https://github.com/tsautier/RatioForge/actions/workflows/release.yml/badge.svg)](https://github.com/tsautier/RatioForge/actions/workflows/release.yml)

**RatioForge** is a modern, .NET 8-powered torrent client simulator that allows you to simulate upload and download statistics with BitTorrent trackers.

> **Note**: This project is a fork and modernization of [RatioMaster.NET](https://github.com/NikolayIT/RatioMaster.NET) by Nikolay Kostov. See [NOTICE.md](NOTICE.md) for full attribution.

## Features

- **Standalone Application**: Does NOT rely on your BitTorrent client (uTorrent, qBittorrent, etc.)
- **No Real Transfer**: Does NOT download/upload actual files - only simulates stats
- **Wide Client Support**: Hardcoded emulations for popular BitTorrent clients:
  - uTorrent (multiple versions)
  - BitComet, Azureus/Vuze
  - ABC, BitLord, BTuga
  - BitTornado, Burst, BitTyrant, BitSpirit
  - Deluge, Transmission, KTorrent
  - And more!
- **Modernized**: Rebuilt for .NET 8 with improved performance and Windows 11 support

## Requirements

- **Windows 10/11** (64-bit recommended)
- No separate .NET runtime is required for the self-contained win-x64 release.

## Installation

1. Download the latest raw executable or zip archive from the [Releases](https://github.com/tsautier/RatioForge/releases) page
2. Extract the archive when using the zip package
3. Run `RatioForge.exe`

## Building from Source

### Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- Visual Studio 2022 (or later) or Rider

### Build Steps

```bash
# Clone the repository
git clone https://github.com/tsautier/RatioForge.git
cd RatioForge

# Restore dependencies
dotnet restore Source/RatioForge.sln

# Build
dotnet build Source/RatioForge.sln --configuration Release

# Run
dotnet run --project Source/RatioForge/RatioForge.csproj
```

### Running Tests

```bash
dotnet test Source/RatioForge.sln
```

## Usage

1. Load a `.torrent` file
2. Select the BitTorrent client to emulate
3. Configure upload/download speeds and ratio
4. Click "Start" to begin sending fake stats to the tracker

For detailed usage instructions, see the built-in help menu.

## What's New in 1.0.10 (RatioForge)

- **Deluge Profiles**: Added client IDs for Deluge 1.3.15 and 2.2.0
- **qBittorrent Profiles**: Added client IDs for qBittorrent 4.2.3, 4.4.5, 4.5.5, 4.6.3, and 5.1.3
- **Tracker Events**: Fixed duplicated Deluge announce event parameters
- **Tests**: Added exact peer ID, User-Agent, and announce URL coverage for the new profiles

See [CHANGELOG.md](CHANGELOG.md) for full version history.

## History

**RatioForge** is based on **RatioMaster.NET** by Nikolay Kostov:
- Original Development: 2006-2016
- Original Author: [Nikolay Kostov (NikolayIT)](http://nikolay.it)
- Original Repository: https://github.com/NikolayIT/RatioMaster.NET

This fork was created in 2026 to modernize the project for current .NET standards while preserving all original functionality.

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Attribution

- **Original Work** (2006-2016): Copyright © Nikolay Kostov
- **Derivative Work** (2026-present): Copyright © Thomas SAUTIER

See [NOTICE.md](NOTICE.md) for full attribution details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Disclaimer

This software is for educational purposes only. Use at your own risk. The developers are not responsible for any misuse or damage caused by this program.

## Support

- **Issues**: [GitHub Issues](https://github.com/tsautier/RatioForge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/tsautier/RatioForge/discussions)

---

**Made with ❤️ using .NET 8**  
**Based on RatioMaster.NET by Nikolay Kostov**
