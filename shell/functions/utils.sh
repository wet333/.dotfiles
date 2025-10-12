# Print timestamped log message with blue color
log() {
    local datetime
    datetime=$(date "+%Y-%m-%d %H:%M:%S.%3N")
    printf "\e[1;34m[%s] ==> %s\e[0m\n" "$datetime" "$*"
}

# List files in current directory only
list_current_files() {
    find . -maxdepth 1 -type f -printf '%f, ' | sed 's/, $//'
    echo ''
}

# List all files recursively from current directory
list_all_files() {
    find . -type f -printf '%f, ' | sed 's/, $//'
    echo ''
}

# Count total items (files + directories) in specified directory
count_directory_items() {
  ls -l $1 | wc -l
}

# Count only directories in specified directory
count_directories() {
  ls -l $1 | grep "^d" | wc -l
}

# Count lines in a file
count_file_lines() {
  cat $1 | wc -l
}

# Count words in a file
count_file_words() {
  cat $1 | wc -w
}

# Count characters in a file
count_file_characters() {
  cat $1 | wc -c
}