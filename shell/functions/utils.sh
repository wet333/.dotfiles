log() {
    local datetime
    datetime=$(date "+%Y-%m-%d %H:%M:%S.%3N")
    printf "\e[1;34m[%s] ==> %s\e[0m\n" "$datetime" "$*"
}

list_dir_files() {
    find . -maxdepth 1 -type f -printf '%f, ' | sed 's/, $//'
    echo ''
}

list_all_files() {
    find . -type f -printf '%f, ' | sed 's/, $//'
    echo ''
}