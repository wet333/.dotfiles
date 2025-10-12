#!/bin/bash

#---------------------------------------------------------------------------------------------------
# Terminal color definitions and color functions
#---------------------------------------------------------------------------------------------------

# Reset
RESET="\033[0m"

# Regular Colors
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

# Bold
BOLD_BLACK="\033[1;30m"
BOLD_RED="\033[1;31m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_PURPLE="\033[1;35m"
BOLD_CYAN="\033[1;36m"
BOLD_WHITE="\033[1;37m"

# Underline
UL_BLACK="\033[4;30m"
UL_RED="\033[4;31m"
UL_GREEN="\033[4;32m"
UL_YELLOW="\033[4;33m"
UL_BLUE="\033[4;34m"
UL_PURPLE="\033[4;35m"
UL_CYAN="\033[4;36m"
UL_WHITE="\033[4;37m"

# Background
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_PURPLE="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

black() { echo -e "${BLACK}$1${RESET}"; }
red() { echo -e "${RED}$1${RESET}"; }
green() { echo -e "${GREEN}$1${RESET}"; }
yellow() { echo -e "${YELLOW}$1${RESET}"; }
blue() { echo -e "${BLUE}$1${RESET}"; }
purple() { echo -e "${PURPLE}$1${RESET}"; }
cyan() { echo -e "${CYAN}$1${RESET}"; }
white() { echo -e "${WHITE}$1${RESET}"; }

# Bold versions
bblack() { echo -e "${BOLD_BLACK}$1${RESET}"; }
bred() { echo -e "${BOLD_RED}$1${RESET}"; }
bgreen() { echo -e "${BOLD_GREEN}$1${RESET}"; }
byellow() { echo -e "${BOLD_YELLOW}$1${RESET}"; }
bblue() { echo -e "${BOLD_BLUE}$1${RESET}"; }
bpurple() { echo -e "${BOLD_PURPLE}$1${RESET}"; }
bcyan() { echo -e "${BOLD_CYAN}$1${RESET}"; }
bwhite() { echo -e "${BOLD_WHITE}$1${RESET}"; }

#---------------------------------------------------------------------------------------------------
# Custom message types for different messaging needs. (Info, Warning, Error, Success, Comments)
#---------------------------------------------------------------------------------------------------

# Custom RGB colors
# Format is: \e[38;2;R;G;Bm where R, G, B are values between 0-255
SUCCESS_COLOR="\e[38;2;140;250;80m"     # Green
INFO_COLOR="\e[38;2;100;200;255m"       # Light blue
COMMENT_COLOR="\e[38;2;160;160;160m"    # Gray
WARNING_COLOR="\e[38;2;245;230;30m"     # Yellow
ERROR_COLOR="\e[38;2;255;70;70m"        # Red

# Helper prefix icons
SUCCESS_PREFIX="[✓] "
INFO_PREFIX="[i] "
COMMENT_PREFIX="> "
WARNING_PREFIX="[!] "
ERROR_PREFIX="[✗] "

# Message functions
success() {
    echo -e "${SUCCESS_COLOR}${SUCCESS_PREFIX}${1}${RESET}"
}

info() {
    echo -e "${INFO_COLOR}${INFO_PREFIX}${1}${RESET}"
}

comment() {
    echo -e "${COMMENT_COLOR}${COMMENT_PREFIX}${1}${RESET}"
}

warning() {
    echo -e "${WARNING_COLOR}${WARNING_PREFIX}${1}${RESET}"
}

error() {
    echo -e "${ERROR_COLOR}${ERROR_PREFIX}${1}${RESET}"
}

#---------------------------------------------------------------------------------------------------
# Pre-Formatted messages
#---------------------------------------------------------------------------------------------------

HLINE_CHAR='-'

hline() {
    # Default character is '-' if not specified
    local char=${1:-"${HLINE_CHAR}"}
    
    # Get terminal width
    local width=$(tput cols)
    
    # Create and print the line
    printf -v line '%*s' "$width"
    echo "${line// /$char}"
}

nline() {
    # Set the char as an space
    local char=" "
  
    # Get terminal width
    local width=$(tput cols)
  
    # Create and print the empty line
    printf -v line '%*s' "$width"
    echo "${line// /$char}"
}

header() {
    local title=$1
    hline '=' && echo " ${title}" && hline '='
}

loader() {
    local percent=$1
    local width=50
    local filled=$((width * percent / 100))
    local empty=$((width - filled))
    
    # Construct the progress bar
    local loadbar="["
    for ((i=0; i<filled; i++)); do
        loadbar+="#"
    done
    for ((i=0; i<empty; i++)); do
        loadbar+=" "
    done
    loadbar+="] ${percent}%"
    
    # Print the progress bar
    echo -e "\r$loadbar"
}