#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y wget software-properties-common
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
if ! apt-cache policy clang-10 | grep -q 'Candidate:'; then
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
  sudo apt-add-repository -y "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main"
fi
sudo apt-get update
sudo apt-get install -y \
  build-essential clang-10 lld-10 g++-7 cmake ninja-build libvulkan1 \
  python python-dev python3-dev python3-pip python3-venv \
  libpng-dev libtiff5-dev libjpeg-dev tzdata sed curl unzip \
  autoconf libtool rsync libxml2-dev git aria2 wget \
  vulkan-tools mesa-vulkan-drivers

sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-10/bin/clang++ 180
sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-10/bin/clang 180
