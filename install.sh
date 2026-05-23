#!/bin/bash

# Portable Superpowers Installer for Vibe CLI
# This script installs and updates superpowers skills for Mistral Vibe

set -euo pipefail

# Configuration
SUPERPOWERS_REPO="https://github.com/obra/superpowers.git"
SUPERPOWERS_DIR="${HOME}/.vibe/superpowers"
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_SCRIPT="${INSTALLER_DIR}/install.sh"
GIT_BIN="$(command -v git || echo 'git')"

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
        ${GIT_BIN} pull --ff-only 2>&1 | while read -r line; do
            log_info "  ${line}"
        done
        cd - >/dev/null
    else
        log_info "Cloning superpowers repository..."
        ${GIT_BIN} clone --depth 1 "${SUPERPOWERS_REPO}" "${target_dir}" 2>&1 | while read -r line; do
            log_info "  ${line}"
        done
    fi
    
    log_success "Superpowers repository ready at ${target_dir}"
}

# Create necessary directory structure in ~/.vibe
setup_vibe_structure() {
    log_info "Setting up Vibe CLI directory structure..."
    
    # Ensure ~/.vibe exists
    mkdir -p "${HOME}/.vibe"
    
    # Create skills directory if it doesn't exist
    mkdir -p "${HOME}/.vibe/skills"
    
    # Create plugins directory
    mkdir -p "${HOME}/.vibe/plugins"
    
    # Create hooks directory
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

# Install plugins
install_plugins() {
    log_info "Installing plugins..."
    
    # For Vibe CLI, we need to adapt the OpenCode plugin
    local opencode_plugin="${SUPERPOWERS_DIR}/.opencode/plugins/superpowers.js"
    local vibe_plugin="${HOME}/.vibe/plugins/superpowers.js"
    
    if [[ -f "${opencode_plugin}" ]]; then
        # Check if we need to create a Vibe-specific adapter
        if [[ ! -f "${vibe_plugin}" ]]; then
            log_info "Creating Vibe plugin adapter..."
            
            # For now, we'll create a simple adapter that loads the skills
            cat > "${vibe_plugin}" << 'EOF'
// Superpowers Plugin for Vibe CLI
// This adapter loads superpowers skills for Mistral Vibe

import { readFileSync, readdirSync, statSync } from 'fs';
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
                
                if (existsSync(skillFile)) {
                    skills.push(item);
                } else if (existsSync(skillYaml)) {
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
            log_success "Vibe plugin adapter created"
        fi
    else
        log_warning "OpenCode superpowers plugin not found, skipping plugin installation"
    fi
}

# Install AGENTS.md if it exists
install_agents_config() {
    log_info "Installing configuration files..."
    
    local agents_file="${SUPERPOWERS_DIR}/AGENTS.md"
    local target_agents="${HOME}/.vibe/AGENTS.md"
    
    # Resolve symlink if it exists
    if [[ -L "${agents_file}" ]]; then
        agents_file="$(readlink -f "${agents_file}")"
    fi
    
    if [[ -f "${agents_file}" ]]; then
        # Create a Vibe-specific AGENTS.md or append to existing
        if [[ ! -f "${target_agents}" ]]; then
            cp "${agents_file}" "${target_agents}"
            log_info "  Created ${target_agents}"
        else
            log_info "  ${target_agents} already exists, skipping"
        fi
    fi
}

# Create update script in ~/.vibe
define_update_script() {
    log_info "Creating update script..."
    
    local update_script="${HOME}/.vibe/update-superpowers.sh"
    
    cat > "${update_script}" << 'EOF'
#!/bin/bash
# Self-updating script for superpowers in Vibe CLI

set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)/superpowers"
INSTALLER_SCRIPT="${INSTALLER_DIR}/install.sh"

# If this script is in ~/.vibe, the installer might be elsewhere
if [[ "$(dirname "${BASH_SOURCE[0]}")" == "${HOME}/.vibe" ]]; then
    # Check if there's a superpowers directory with install.sh
    if [[ -f "${INSTALLER_SCRIPT}" ]]; then
        exec "${INSTALLER_SCRIPT}" "$@"
    else
        echo "Error: Cannot find installer at ${INSTALLER_SCRIPT}"
        echo "Please run the installer directly from the superpowers directory"
        exit 1
    fi
else
    # We're being called from the superpowers directory
    exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install.sh" "$@"
fi
EOF
    
    chmod +x "${update_script}"
    log_success "Update script created at ${update_script}"
}

# Self-update functionality
self_update() {
    log_info "Checking for updates to installer..."
    
    # Get the latest version of install.sh from the repository
    local temp_file=$(mktemp)
    local latest_url="https://raw.githubusercontent.com/obra/superpowers/main/.vibe/install.sh"
    
    if command_exists curl; then
        curl -s -f "${latest_url}" -o "${temp_file}" || {
            log_warning "Could not fetch latest installer (URL may not exist yet)"
            rm -f "${temp_file}"
            return 0
        }
    elif command_exists wget; then
        wget -q -O "${temp_file}" "${latest_url}" || {
            log_warning "Could not fetch latest installer (URL may not exist yet)"
            rm -f "${temp_file}"
            return 0
        }
    else
        log_warning "Neither curl nor wget available, skipping self-update"
        return 0
    fi
    
    # Compare with current version
    if ! diff -q "${INSTALLER_SCRIPT}" "${temp_file}" >/dev/null 2>&1; then
        log_info "New version of installer found, updating..."
        cp "${temp_file}" "${INSTALLER_SCRIPT}"
        chmod +x "${INSTALLER_SCRIPT}"
        log_success "Installer updated successfully"
    else
        log_info "Installer is already up to date"
    fi
    
    rm -f "${temp_file}"
}

# Main installation function
do_install() {
    check_prerequisites
    setup_vibe_structure
    setup_superpowers_repo
    install_skills
    install_plugins
    install_agents_config
    define_update_script
    
    # Create a convenience symlink in ~/.vibe for easy access
    if [[ ! -L "${HOME}/.vibe/superpowers" ]]; then
        ln -sf "${SUPERPOWERS_DIR}" "${HOME}/.vibe/superpowers"
    fi
    
    log_success "Superpowers installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your Vibe CLI"
    echo "  2. To update superpowers in the future, run: ${HOME}/.vibe/update-superpowers.sh"
    echo "  3. Or run this installer again: ${INSTALLER_SCRIPT}"
}

# Main update function
do_update() {
    check_prerequisites
    self_update
    setup_superpowers_repo
    install_skills
    install_plugins
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
    do_install
fi
