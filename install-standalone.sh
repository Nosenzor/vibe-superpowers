#!/bin/bash

# Standalone Portable Superpowers Installer for Vibe CLI
# This is a single-file installer that can be downloaded and run directly
# Usage: curl -sSL https://raw.githubusercontent.com/RomainRev/UltraVibe/superpowers/main/install-standalone.sh | bash

set -euo pipefail

# Configuration - These can be overridden by environment variables
SUPERPOWERS_REPO="${SUPERPOWERS_REPO:-https://github.com/obra/superpowers.git}"
SUPERPOWERS_DIR="${SUPERPOWERS_DIR:-${HOME}/.vibe/superpowers}"
INSTALLER_URL="${INSTALLER_URL:-https://raw.githubusercontent.com/RomainRev/UltraVibe/superpowers/main/install-standalone.sh}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Download file using curl or wget
download_file() {
    local url="$1"
    local dest="$2"
    
    if command_exists curl; then
        curl -s -f -L "${url}" -o "${dest}"
    elif command_exists wget; then
        wget -q -O "${dest}" "${url}"
    else
        log_error "Neither curl nor wget is available. Cannot download files."
        return 1
    fi
}

# Self-update functionality
self_update() {
    log_info "Checking for updates to installer..."
    
    local temp_file=$(mktemp)
    
    if download_file "${INSTALLER_URL}" "${temp_file}"; then
        # Compare with current version
        if ! diff -q "$0" "${temp_file}" >/dev/null 2>&1; then
            log_info "New version of installer found, updating..."
            # Try to update ourselves
            if cp "${temp_file}" "$0" 2>/dev/null; then
                chmod +x "$0"
                log_success "Installer updated successfully"
                log_info "Re-executing updated installer..."
                exec "$0" "$@"
            else
                log_warning "Could not update installer (may be running from pipe)"
            fi
        else
            log_info "Installer is already up to date"
        fi
        rm -f "${temp_file}"
    else
        log_warning "Could not fetch latest installer"
        rm -f "${temp_file}"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command_exists git; then
        log_error "git is required but not installed. Please install git first."
        exit 1
    fi
    
    if ! command_exists curl && ! command_exists wget; then
        log_error "curl or wget is required to download files. Please install one of them."
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Clone or update the superpowers repository
setup_superpowers_repo() {
    local target_dir="${SUPERPOWERS_DIR}"
    
    if [[ -d "${target_dir}/.git" ]]; then
        log_info "Updating existing superpowers repository..."
        cd "${target_dir}"
        git pull --ff-only 2>&1 | while read -r line; do
            log_info "  ${line}"
        done
        cd - >/dev/null
    else
        log_info "Cloning superpowers repository..."
        git clone --depth 1 "${SUPERPOWERS_REPO}" "${target_dir}" 2>&1 | while read -r line; do
            log_info "  ${line}"
        done
    fi
    
    log_success "Superpowers repository ready at ${target_dir}"
}

# Create necessary directory structure in ~/.vibe
setup_vibe_structure() {
    log_info "Setting up Vibe CLI directory structure..."
    
    mkdir -p "${HOME}/.vibe"
    mkdir -p "${HOME}/.vibe/skills"
    mkdir -p "${HOME}/.vibe/plugins"
    mkdir -p "${HOME}/.vibe/hooks"
    
    log_success "Vibe directory structure created"
}

# Install skills from superpowers
install_skills() {
    log_info "Installing skills from superpowers..."
    
    local source_skills="${SUPERPOWERS_DIR}/skills"
    local target_skills="${HOME}/.vibe/skills"
    
    if [[ ! -d "${source_skills}" ]]; then
        log_error "Superpowers skills directory not found at ${source_skills}"
        exit 1
    fi
    
    # Create symlinks for each skill directory
    local installed_count=0
    for skill_dir in "${source_skills}"/*/; do
        if [[ -d "${skill_dir}" ]]; then
            local skill_name=$(basename "${skill_dir}")
            local target="${target_skills}/${skill_name}"
            
            # Remove existing symlink or directory if it exists
            if [[ -e "${target}" || -L "${target}" ]]; then
                rm -rf "${target}"
            fi
            
            # Create symlink to the skill
            ln -s "${skill_dir}" "${target}"
            log_info "  Installed skill: ${skill_name}"
            ((installed_count++))
        fi
    done
    
    if [[ ${installed_count} -eq 0 ]]; then
        log_warning "No skills were installed. Check if ${source_skills} contains skill directories."
    else
        log_success "Installed ${installed_count} skills"
    fi
}

# Install plugin adapter
install_plugin() {
    log_info "Installing Vibe CLI plugin adapter..."
    
    local vibe_plugin="${HOME}/.vibe/plugins/superpowers.js"
    
    cat > "${vibe_plugin}" << 'EOF'
// Superpowers Plugin for Vibe CLI
// This adapter loads superpowers skills for Mistral Vibe

import { readdirSync, statSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load all skills from the skills directory
function loadSkills() {
    const skillsDir = join(__dirname, '..', 'skills');
    const skills = [];
    
    try {
        const items = readdirSync(skillsDir);
        for (const item of items) {
            const itemPath = join(skillsDir, item);
            const stat = statSync(itemPath);
            
            if (stat.isDirectory()) {
                // Look for skill.md or skill.yaml in the directory
                const skillFile = join(itemPath, 'skill.md');
                const skillYaml = join(itemPath, 'skill.yaml');
                const skillJson = join(itemPath, 'skill.json');
                
                if (existsSync(skillFile) || existsSync(skillYaml) || existsSync(skillJson)) {
                    skills.push(item);
                }
            }
        }
    } catch (err) {
        console.warn('Superpowers: Could not load skills:', err.message);
    }
    
    return skills;
}

// Initialize superpowers
export function initialize() {
    const skills = loadSkills();
    console.log(`Superpowers: Loaded ${skills.length} skills`);
    return { skills };
}

export { initialize };
EOF
    
    log_success "Vibe plugin adapter created at ${vibe_plugin}"
}

# Create update script in ~/.vibe
create_update_script() {
    log_info "Creating update script..."
    
    local update_script="${HOME}/.vibe/update-superpowers.sh"
    
    cat > "${update_script}" << UPDATE_EOF
#!/bin/bash
# Self-updating script for superpowers in Vibe CLI

set -euo pipefail

# Use the standalone installer for updates
INSTALLER_URL="${INSTALLER_URL}"

# Try to download and run the installer
temp_script=\$(mktemp)

if command -v curl >/dev/null 2>&1; then
    curl -s -f -L "\${INSTALLER_URL}" -o "\${temp_script}"
elif command -v wget >/dev/null 2>&1; then
    wget -q -O "\${temp_script}" "\${INSTALLER_URL}"
else
    echo "Error: Neither curl nor wget is available" >&2
    exit 1
fi

chmod +x "\${temp_script}"
exec "\${temp_script}" --update "\$@"
UPDATE_EOF
    
    chmod +x "${update_script}"
    log_success "Update script created at ${update_script}"
}

# Main installation function
do_install() {
    check_prerequisites
    setup_vibe_structure
    setup_superpowers_repo
    install_skills
    install_plugin
    create_update_script
    
    # Create a convenience symlink in ~/.vibe for easy access
    if [[ ! -L "${HOME}/.vibe/superpowers" ]]; then
        ln -sf "${SUPERPOWERS_DIR}" "${HOME}/.vibe/superpowers"
    fi
    
    log_success "Superpowers installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your Vibe CLI"
    echo "  2. To update superpowers in the future, run: ${HOME}/.vibe/update-superpowers.sh"
    echo "  3. Or re-run this installer with --update"
}

# Main update function
do_update() {
    check_prerequisites
    self_update
    setup_superpowers_repo
    install_skills
    install_plugin
    log_success "Superpowers updated successfully!"
}

# Parse command line arguments
ACTION="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --update|-u)
            ACTION="update"
            shift
            ;;
        --force|-f)
            FORCE=1
            shift
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --update, -u    Update existing installation"
            echo "  --force, -f     Force reinstall/refresh"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $(basename "$0")              # Initial installation"
            echo "  $(basename "$0") --update     # Update superpowers"
            echo ""
            echo "Environment Variables:"
            echo "  SUPERPOWERS_REPO  Git repository URL (default: https://github.com/obra/superpowers.git)"
            echo "  SUPERPOWERS_DIR   Installation directory (default: ~/.vibe/superpowers)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Execute the appropriate action
if [[ "${ACTION}" == "update" ]]; then
    do_update
else
    # Check if we should self-update before installing
    if [[ "${ACTION}" == "install" && "$#" -eq 0 ]]; then
        self_update
    fi
    do_install
fi
