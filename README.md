# Cursor Companion

[![CI](https://github.com/clezcoding/cursor-companion/actions/workflows/ci.yml/badge.svg)](https://github.com/clezcoding/cursor-companion/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Companion and custom agent skills for Google Antigravity & Stitch workflows, including a real-time HUD for Cursor IDE usage powered by OpenUsage.

## Features

- **Agent Skills**: Pre-configured specialized skills for Stitch design systems, React/React Native generation, Remotion walkthroughs, and UI prompt enhancement.
- **Cursor Usage HUD**: Real-time HUD displaying Cursor Model Pools, Limits, and Reset dates via the local OpenUsage API.
- **Automated Dependency Updates**: Configured via GitHub Dependabot (`.github/dependabot.yml`).
- **Automerge**: Configured via Kodiak (`.kodiak.toml`).
- **Automated Releases**: Managed with Conventional Commits and Release Please.

## Quick Setup & Notes

### Kodiak Automerge
To enable Kodiak to automatically merge pull requests with the `automerge` label:
1. Install the [Kodiak GitHub App](https://github.com/apps/kodiak-app) on this repository.
2. Ensure Branch Protection rules require CI checks to pass before merging.

## Contributing & Security

- Read our [Contributing Guide](CONTRIBUTING.md) to get started.
- Check our [Security Policy](SECURITY.md) for vulnerability reporting.

## License

This project is licensed under the [MIT License](LICENSE).
