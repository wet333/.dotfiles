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