# Link current directory to Ghost themes folder
create-ghost-theme-symlink() {
    if [ -z "$1" ]; then
        echo "Usage: ghost-link <theme-name>"
        echo "Example: ghost-link my-theme"
        return 1
    fi
    
    local theme_name="$1"
    local ghost_themes="$HOME/Programming/Apps/Ghost/content/themes"
    local current_dir="$(pwd)"
    local target="$ghost_themes/$theme_name"
    
    # Check if Ghost themes directory exists
    if [ ! -d "$ghost_themes" ]; then
        echo "Error: Ghost themes directory not found at $ghost_themes"
        return 1
    fi
    
    # Check if symlink/directory already exists
    if [ -e "$target" ]; then
        echo "Warning: $target already exists"
        read -p "Remove it and create new symlink? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$target"
        else
            echo "Aborted."
            return 1
        fi
    fi
    
    # Create the symlink
    ln -s "$current_dir" "$target"
    echo "✓ Linked $current_dir"
    echo "  → $target"
}