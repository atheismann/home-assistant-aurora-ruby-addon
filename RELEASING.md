# Release Process

This add-on uses semantic versioning and GitHub releases.

## Creating a New Release

### 1. Update Version

Update the version in both config files:
- `config.yaml` - Update `version: "X.Y.Z"`
- `config.json` - Update `"version": "X.Y.Z"`

### 2. Update Changelog

Add release notes to `CHANGELOG.md`:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Fixed
- Bug fixes

### Removed
- Removed features
```

### 3. Commit Changes

```bash
git add config.yaml config.json CHANGELOG.md
git commit -m "Bump version to X.Y.Z"
git push origin main
```

### 4. Create GitHub Release

1. Go to https://github.com/atheismann/home-assistant-aurora-ruby-addon/releases/new
2. Click "Choose a tag" and create a new tag: `vX.Y.Z` (e.g., `v1.1.0`)
3. Set release title: `vX.Y.Z`
4. Copy release notes from CHANGELOG.md into the description
5. Click "Publish release"

### 5. Automated Build

Once the release is published:
- GitHub Actions will automatically trigger
- Docker images will be built for aarch64 and amd64
- Images will be pushed to GitHub Container Registry as:
  - `ghcr.io/atheismann/waterfurnace-aurora-aarch64:X.Y.Z`
  - `ghcr.io/atheismann/waterfurnace-aurora-amd64:X.Y.Z`

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0) - Incompatible API changes
- **MINOR** (0.X.0) - New features, backwards compatible
- **PATCH** (0.0.X) - Bug fixes, backwards compatible

## Current Version

Check `config.yaml` or `config.json` for the current version.

## Release Checklist

- [ ] Version bumped in config.yaml
- [ ] Version bumped in config.json
- [ ] CHANGELOG.md updated
- [ ] Changes committed and pushed
- [ ] GitHub release created with tag
- [ ] Release notes copied from CHANGELOG
- [ ] Build workflow completed successfully
- [ ] Add-on tested with new version
