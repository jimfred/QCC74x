#!/bin/bash
set -e

echo "🔧 Setting up Zephyr development environment..."

# Install dependencies
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    git cmake ninja-build gperf ccache dfu-util \
    device-tree-compiler wget python3-dev python3-pip \
    python3-setuptools python3-tk python3-wheel xz-utils \
    file make gcc gcc-multilib g++-multilib libsdl2-dev \
    libmagic1

# Install West
pip3 install --user -U west
export PATH="$HOME/.local/bin:$PATH"

# Setup Zephyr (optional - can be done manually)
# west init ~/zephyrproject
# cd ~/zephyrproject
# west update
# west zephyr-export

echo "✅ Development environment setup complete!"
echo "📝 Next steps:"
echo "   1. Run: west init ~/zephyrproject"
echo "   2. Run: cd ~/zephyrproject && west update"
echo "   3. Download Zephyr SDK from: https://github.com/zephyrproject-rtos/sdk-ng/releases"
