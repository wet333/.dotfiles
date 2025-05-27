# .dotfiles

A comprehensive dotfiles management system that transforms any fresh Linux installation into a fully-configured development environment with minimal effort.

## Directory Structure

* `shell/`: Bash terminal configuration files that define your command-line experience, including aliases for common commands, environment variables for system settings, and prompt customization to display useful information in your terminal.
* `shell/functions/`: Includes a curated collection of reusable Bash functions that are automatically sourced by the shell configuration. These functions streamline repetitive command-line tasks and provide personalized shortcuts for common development workflows.
* `scripts/`: Stores standalone utility scripts designed for various automation, setup, or maintenance tasks. These scripts can be executed independently and serve specific purposes beyond the initial setup process.
* `installation/`: Contains specialized scripts that are designed to run exclusively during the initial setup and installation process. These scripts handle one-time configuration tasks such as installing development tools, setting up programming environments, and configuring system-level settings.
* `install.sh`: The master installation script that orchestrates the entire setup process.

## How to Add features

The modular design of this dotfiles system makes it straightforward to extend functionality by adding new components.

### Adding new Setup/Configuration scripts

When you want to add support for a new development environment or tool, create a dedicated script within the installation directory. Each script should focus on a single responsibility and include clear feedback about its progress.

Here's an example that demonstrates the current Node.js environment setup:

```bash
# Example for configuring node.js environment, currently used.
#!/bin/bash

echo "Setting up Node.js development software and tools..."

# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

# Source it
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 22

# Verify the Node.js version:
node -v
nvm current

# Download and install pnpm:
corepack enable pnpm

# Verify pnpm version:
pnpm -v

echo "Node.js is ready to code!"
```

After creating your installation script, you must register it in the main installer file `install.sh` to ensure it executes during the setup process. Add the following line in the appropriate section:

```bash
bash "$CLONE_DIR/installation/setup_script_example.sh"
```

This approach ensures that your new configuration becomes part of the automated setup process and will be applied consistently across different machines.

## Installation

This installation system is primarily designed for fresh Linux installations, though it can also be used to update the existing configuration.

**⚠️ Warning:** The installation script (`install.sh`) will likely modify files in your home directory (e.g., `~/.bashrc`, `~/.profile`). It might create symbolic links or copy files, potentially overwriting existing configurations. Furthermore, the script may delete specific files or directories if they conflict with the new setup.

**👉 It is strongly recommended to:**

1. **Review** the `install.sh` script to understand what it does.
2. Run one of this commands:

```bash
    sudo apt update && \
    sudo apt install -y wget git && \
    wget -qO- https://raw.githubusercontent.com/wet333/dotfiles/master/install.sh | bash
```

```bash
    sudo apt update && \
    sudo apt install -y curl git && \
    curl -sL https://raw.githubusercontent.com/wet333/dotfiles/master/install.sh | bash
```
