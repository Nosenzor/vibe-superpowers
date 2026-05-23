# Superpowers for Vibe CLI

This repository contains a portable installer that sets up the [obra/superpowers](https://github.com/obra/superpowers) skills for Mistral Vibe CLI.

**Repository:** https://github.com/Nosenzor/vibe-superpowers

## What is Superpowers?

Superpowers is a collection of high-quality skills for AI coding agents. Originally designed for OpenCode, Claude Code, and other harnesses, these skills provide:

- Brainstorming and planning workflows
- Code review and verification processes
- Debugging methodologies
- Project management patterns
- And much more

## Installation

There are two ways to install superpowers for Vibe CLI:

### Method 1: Using the Standalone Installer (Recommended)

This is the easiest method - just download and run the standalone installer:

```bash
# Download and run directly (requires bash)
curl -sSL https://raw.githubusercontent.com/Nosenzor/vibe-superpowers/main/install-standalone.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/Nosenzor/vibe-superpowers/main/install-standalone.sh | bash

# To update later
~/.vibe/update-superpowers.sh --update
```

### Method 2: Clone and Run

If you want to inspect the installer code first:

```bash
# Clone this repository
git clone https://github.com/Nosenzor/vibe-superpowers.git
cd vibe-superpowers

# Run the installer
./install.sh

# Or use the standalone version
./install-standalone.sh
```

The installer will:
1. Clone the obra/superpowers repository to `~/.vibe/superpowers`
2. Create symlinks to all skills in `~/.vibe/skills`
3. Set up necessary directory structure
4. Create an update script at `~/.vibe/update-superpowers.sh`

## Updating

To update superpowers to the latest version:

```bash
# Method 1: Using the update script
~/.vibe/update-superpowers.sh --update

# Method 2: Run the installer again
cd ~/vibe-superpowers
./install.sh --update

# Method 3: Pull updates manually
cd ~/.vibe/superpowers
git pull
```

## How It Works

The installer creates a portable setup with these key features:

1. **Skill Symlinks**: Instead of copying files, the installer creates symlinks from `~/.vibe/skills` to the actual skill directories in `~/.vibe/superpowers/skills`. This means:
   - Skills are always up-to-date with the repository
   - Easy to update by pulling the repository
   - No duplicate files

2. **Self-Updating**: The installer includes a self-update mechanism that can check for newer versions of itself.

3. **Portable**: The installer can be run from any location, and it will set up the correct structure in `~/.vibe`.

## Directory Structure

After installation, your `~/.vibe` directory will look like:

```
.vibe/
├── superpowers/           # Symlink to the cloned repository
├── skills/                # Symlinks to individual skill directories
│   ├── brainstorming -> superpowers/skills/brainstorming
│   ├── dispatching-parallel-agents -> superpowers/skills/dispatching-parallel-agents
│   └── ...
├── plugins/
│   └── superpowers.js    # Vibe CLI plugin adapter
├── AGENTS.md             # Configuration file (optional)
└── update-superpowers.sh  # Update script
```

## Customization

### Using a Specific Version

To use a specific version of superpowers, you can either:

**For install.sh:** Modify the `SUPERPOWERS_REPO` variable in the script:
```bash
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git#v5.0.3"
```

**For the standalone installer:** Use environment variables:
```bash
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git#v5.0.3" ./install-standalone.sh
```

### Environment Variables (Standalone Installer Only)

The standalone installer supports these environment variables:

- `SUPERPOWERS_REPO`: Git repository URL (default: `https://github.com/obra/superpowers.git`)
- `SUPERPOWERS_DIR`: Installation directory (default: `~/.vibe/superpowers`)
- `INSTALLER_URL`: URL to check for installer updates (default: GitHub URL of this script)

Example:
```bash
# Install to a custom location
SUPERPOWERS_DIR="${HOME}/my-custom-superpowers" ./install-standalone.sh

# Use a specific branch or tag
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git#v5.0.3" ./install-standalone.sh
```

Then run the installer again.

### Adding Custom Skills

You can add your own skills by creating directories in `~/.vibe/skills`. The installer will not overwrite your custom skills, but it may create symlinks with the same names if they conflict with superpowers skills.

## Uninstallation

To remove superpowers:

```bash
# Remove the superpowers directory
rm -rf ~/.vibe/superpowers

# Remove skill symlinks
rm -rf ~/.vibe/skills

# Remove plugin and update script
rm -f ~/.vibe/plugins/superpowers.js
rm -f ~/.vibe/update-superpowers.sh

# Optionally remove AGENTS.md if you don't need it
rm -f ~/.vibe/AGENTS.md
```

## Troubleshooting

### "git not found"

Ensure git is installed and in your PATH:

```bash
# On macOS
xcode-select --install

# On Ubuntu/Debian
sudo apt install git

# On RHEL/CentOS
sudo yum install git
```

### "curl or wget not found"

The installer needs either curl or wget for self-updates:

```bash
# On macOS (curl is pre-installed)
# On Ubuntu/Debian
sudo apt install curl

# On RHEL/CentOS
sudo yum install curl
```

### Skills not loading

1. Check that `~/.vibe/skills` contains symlinks to the skill directories
2. Verify that `~/.vibe/superpowers/skills` exists and has the skill directories
3. Restart your Vibe CLI

### Permission denied

Make sure the scripts are executable:

```bash
chmod +x ~/vibe-superpowers/install.sh
chmod +x ~/.vibe/update-superpowers.sh
```

## Contributing

This installer is a simple wrapper around the obra/superpowers repository. For issues with the skills themselves, please file issues at:

- [obra/superpowers GitHub Issues](https://github.com/obra/superpowers/issues)

For issues with this installer, please check the repository where you found it.

## License

This installer is provided as-is. The superpowers skills are licensed under the terms specified in the obra/superpowers repository.
