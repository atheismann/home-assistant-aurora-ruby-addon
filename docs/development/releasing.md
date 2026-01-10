# Release Process

This add-on uses semantic versioning and automated releases.

## Automated Releases (Recommended)

Releases are **automatically created** when changes are pushed to main (via PR merge or direct push).

### Via Pull Request (Recommended)

Add a label to your PR to control version bumping:

- **`major`** - Breaking changes (X.0.0) - e.g., v1.0.0 → v2.0.0
- **`minor`** - New features (0.X.0) - e.g., v1.2.0 → v1.3.0
- **No label or `patch`** - Bug fixes (0.0.X) - e.g., v1.2.3 → v1.2.4

**Workflow:**

1. Create a PR with your changes
2. Add appropriate label (`major`, `minor`, or leave as patch)
3. Merge the PR to main
4. Automation handles the rest

### Via Direct Push to Main

If pushing directly to main, use commit message prefixes:

- **`[major]`** or **`BREAKING CHANGE:`** - Major version bump
- **`[minor]`** or **`feat:`** or **`feature:`** - Minor version bump
- **Anything else** - Patch version bump

**Examples:**

```bash
git commit -m "feat: add network connection support"  # Minor bump
git commit -m "fix: resolve gem installation error"   # Patch bump
git commit -m "[major] remove deprecated architectures" # Major bump
```

### Skip Release

To push changes without triggering a release, include `[skip release]` or `[skip ci]` in your commit message:

```bash
git commit -m "docs: update README [skip release]"
```

### What Happens Automatically

When code is pushed to main:

1. Build workflow runs (lint and build for all architectures)
2. If build succeeds, auto-release workflow triggers
3. Calculates new version based on commit message
4. Updates `config.yaml` with new version
5. Updates `CHANGELOG.md` with change info
6. Commits changes with `[skip ci]`
7. Creates GitHub release with tag
8. Release workflow triggers to build and publish Docker images

## Manual Releases (Alternative)

If you prefer manual control, you can still create releases manually.

### 1. Update Version Manually

Edit both config files:

- `config.yaml` - Update `version: "X.Y.Z"`

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
git add config.yaml CHANGELOG.md
git commit -m "Bump version to X.Y.Z [skip release]"
git push origin main
```

Note: Use `[skip release]` to prevent auto-release from also running.

### 4. Create GitHub Release

1. Go to <https://github.com/atheismann/home-assistant-aurora-ruby-addon/releases/new>
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
