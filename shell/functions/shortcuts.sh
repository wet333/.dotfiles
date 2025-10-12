# Shortcuts - Prefix (goto_...)

cdh() {
  cd "$HOME" || exit
}

dots() {
    cd "$HOME/dotfiles" || exit
    cursor .
}

cursor() {
    local cursor_dir="/home/wet333/Programming/Apps/Cursor"
    local newest=$(command ls "$cursor_dir"/*.AppImage 2>/dev/null | sort -V | tail -n1)
    
    if [ -z "$newest" ]; then
        echo "No AppImage found in $cursor_dir"
        return 1
    fi
    
    echo "Launching: ${newest##*/}"
    nohup "$newest" "$@" > /dev/null 2>&1 &
    disown
} 