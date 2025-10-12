txt_date_dmy() {
  date '+%d-%m-%Y'
}

txt_date_ymd() {
  date '+%Y-%m-%d'
}

txt_time_hms() {
  date '+%H:%M:%S'
}

txt_time_hm() {
  date '+%H:%M'
}

txt_random() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
}

txt_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

txt_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

txt_cap() {
    if [[ -z "$1" ]]; then
        echo "Usage: txt_cap <string>"
        return 1
    fi

    txt_upper_at "$1" "$(_txt_first_alpha "$1")"
}

txt_upper_at(){
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: txt_upper_at <string> <index>"
        return 1
    fi

    local input="$1"
    local index="$2"

    local part1="${input:0:index}"
    local char="${input:index:1}"
    char=$(echo "$char" | tr '[:lower:]' '[:upper:]')
    local part3="${input:index+1}"

    echo "$part1$char$part3"
}

_txt_first_alpha() {
     local input="$1"
     local length=${#input}

     for (( i=0; i<length; i++ )); do
         char="${input:i:1}"
         if [[ "$char" =~ [a-zA-Z] ]]; then
             echo "$i"
             return 0
         fi
     done

     echo "Error: No alphanumeric character found in string"
     return 1
}