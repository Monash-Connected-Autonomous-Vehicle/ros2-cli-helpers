# Install all ROS 2 dependencies using rosdep
rosdep_install() {
  if [[ ! -d src ]]; then
    echo "Error: src/ directory not found."
    return 1
  fi
  echo "Installing ROS 2 dependencies (ROS_DISTRO=${ROS_DISTRO:-unset})"
  rosdep install -y --from-paths src --ignore-src --rosdistro "${ROS_DISTRO}" \
    || { echo "rosdep install failed."; return 1; }
  echo "Dependency installation complete."
}

# Build all packages with colcon (Release mode)
cb() {
  echo "Starting colcon build (Release mode)..."
  colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release \
    || { echo "Build failed."; return 1; }
  echo "Build complete."
}

# Clean specific packages from build/ and install/
clnp() {
  if [[ ! -d build || ! -d install ]]; then
    echo "Error: build/ or install/ directory not found."
    return 1
  fi
  if [[ $# -eq 0 ]]; then
    echo "Usage: clnp <package1> [package2 ...]"
    return 1
  fi
  for pkg in "$@"; do
    for dir in build install; do
      target="$dir/$pkg"
      if [[ -d "$target" ]]; then
        echo "Removing $target"
        rm -rf "$target"
      else
        echo "Skipping $target (not found)"
      fi
    done
  done
}

clnb() {
  if [[ ! -d build || ! -d install ]]; then
    echo "Error: build/ or install/ directory not found."
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    echo "Usage: clnb <package1> [package2 ...]"
    return 1
  fi

  echo "Cleaning packages: $*"
  for pkg in "$@"; do
    for dir in build install; do
      target="$dir/$pkg"
      if [[ -d "$target" ]]; then
        echo "Removing $target"
        rm -rf "$target"
      else
        echo "Skipping $target (not found)"
      fi
    done
  done

  echo "Rebuilding packages: $*"
  colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-select "$@" \
    || { echo "Build failed."; return 1; }

  echo "Build complete."
}

# Build up to specific packages using colcon
cbu() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: cbu <package1> [package2 ...]"
    return 1
  fi
  echo "Building packages up to: \"$*\""
  colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --packages-up-to "$@" \
    || { echo "Build failed."; return 1; }
  echo "Build complete."
}

# Tab completions

# Auto-complete for clnp (uses directories from build/ and install/)
_ros2_clean_completion() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local suggestions=$(find build install -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null)
  COMPREPLY=( $(compgen -W "$suggestions" -- "$cur") )
}
complete -F _ros2_clean_completion clnp

# Auto-complete for cbu (uses package.xml directories under src/)
_ros2_build_up_to_completion() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local pkgs=$(colcon list --names-only 2>/dev/null)
  COMPREPLY=( $(compgen -W "$pkgs" -- "$cur") )
}
complete -F _ros2_build_up_to_completion cbu
complete -F _ros2_build_up_to_completion clnb