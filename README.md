# Cursor Companion

Companion and custom agent skills for Google Antigravity & Stitch workflows.

## Features

- **Agent Skills**: Pre-configured specialized skills for Stitch design systems, React/React Native generation, Remotion walkthroughs, and UI prompt enhancement.
- **Automated Dependency Updates**: Configured via GitHub Dependabot (`.github/dependabot.yml`).
- **Automerge**: Configured via Kodiak (`.kodiak.toml`).

## Quick Setup & Notes

### Kodiak Automerge
To enable Kodiak to automatically merge pull requests with the `automerge` label:
1. Install the [Kodiak GitHub App](https://github.com/apps/kodiak-app) on this repository.
2. Ensure Branch Protection rules require CI checks to pass before merging.
