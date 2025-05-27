export HISTFILE="$HOME/.bash_history"
export HISTSIZE=100000
export HISTFILESIZE=100000

export HISTCONTROL=ignoreboth
export HISTFORMAT="%F %T $(whoami) %h: %s"

shopt -s histappend
shopt -s cmdhist

# Function to show history statistics
hist_stats() {
    header "History Statistics"
    echo "Total commands: $(wc -l < "$HISTFILE")"
    echo "History file size: $(du -h "$HISTFILE" | cut -f1)"
    echo "History file location: $HISTFILE"
    echo ""
    echo "Top 10 commands:"
    hist_top 10
}

hist_top() {
    local count=${1:-10}
    history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n"$count"
}

hist_backup() {
    local backup_dir="$HOME/.history_backups"
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/history_$(date +%Y%m%d_%H%M%S)"
    cp "$HISTFILE" "$backup_file"
    echo "History backed up to: $backup_file"
}