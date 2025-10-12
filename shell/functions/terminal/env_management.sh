#!/bin/bash

# Environment utilities - Prefix (env_...)

env_ls() {
    printenv | sort
}

# Environment Variables Manager
# =============================
#
# This functions will help you manage persistent environment variables. It allows you to
# set and save environment variables to a file, and load them into your current session.
#
# Functions:
# ----------
#
# 1. env_set_var <variable_name> <value>
#    Sets an environment variable and saves it to the file. If the variable already
#    exists, it prompts for confirmation before updating.
#
# 2. env_load
#    Loads all environment variables from the file into the current session.
#    This function is automatically called when the script is sourced and
#    can be manually called to reload variables during a session.
#
# Configuration:
# --------------
#
# - ENV_FILE: Path to the file where environment variables are stored, default:
#       "$HOME/.custom_env_vars"
#
# Usage:
# ------
#
# Use the functions as needed:
#    - env_set_var MY_VAR "my value"
#    - env_load
#    - env_ls


# Function to check if a variable is a custom variable (in our file) or unset
__is_custom_var() {
    local var_name="$1"
    if grep -q "^export $var_name=" "$ENV_FILE" 2>/dev/null || [[ -z "${!var_name}" ]]; then
        return 0  # It is a custom variable or unset
    else
        return 1  # It is a system variable not in our custom file
    fi
}

# File path for storing environment variables
ENV_FILE="$HOME/.custom_env_vars"

# Function to set an environment variable
env_set_var() {
    local var_name="$1"
    local new_value="$2"
    local old_value

    if ! __is_custom_var "$var_name"; then
        echo "Error: $var_name is an existing system variable and cannot be modified."
        return 1
    fi

    # Check if the variable already exists in the file
    if grep -q "^export $var_name=" "$ENV_FILE" 2>/dev/null; then
        old_value=$(grep "^export $var_name=" "$ENV_FILE" | cut -d'=' -f2-)
        echo "Current value of $var_name: $old_value --> New value: $new_value"

        # Ask for confirmation before updating
        read -p "Do you want to replace the value $old_value with $new_value? (y/n): " confirm

        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            sed -i "s|^export $var_name=.*|export $var_name=\"$new_value\"|" "$ENV_FILE"
            echo "Value updated."
            env_load # Reload the environment variables
        else
            echo "Operation cancelled."
            return
        fi
    else
        echo "export $var_name=\"$new_value\"" >>"$ENV_FILE"
        echo "New variable added."
        env_load # Reload the environment variables
    fi
}

# Function to load environment variables
env_load() {
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        echo "Environment variables loaded from $ENV_FILE"
    else
        echo "Environment file not found: $ENV_FILE, No variables loaded."

        echo "Creating new environment file: $ENV_FILE"
        status=$(touch "$ENV_FILE" 2>&1)
        if [[ $? -eq 0 ]]; then
            echo "Environment file created successfully."
        else
            echo "Error creating environment file: $status"
        fi
    fi
}

# Function to delete an environment variable
env_delete_var() {
    local var_name="$1"
    local current_value

    if ! __is_custom_var "$var_name"; then
        echo "Error: $var_name is an existing system variable and cannot be deleted."
        return 1
    fi

    if grep -q "^export $var_name=" "$ENV_FILE" 2>/dev/null; then

        current_value=$(grep "^export $var_name=" "$ENV_FILE" | cut -d'=' -f2-)
        echo "Current value of $var_name: $current_value"

        read -p "Are you sure you want to delete this variable? (y/n): " confirm

        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            sed -i "/^export $var_name=/d" "$ENV_FILE"
            unset "$var_name"
            echo "Variable $var_name has been deleted from $ENV_FILE and unset from the current session."
        else
            echo "Operation cancelled. Variable $var_name was not deleted."
        fi
    else
        echo "Variable $var_name not found in $ENV_FILE."
    fi
}

# Function to list user-defined variables
env_user_ls() {
    if [[ -f "$ENV_FILE" ]]; then
        while IFS= read -r line; do
            if [[ $line == export* ]]; then
                var_name=$(echo "$line" | cut -d'=' -f1 | cut -d' ' -f2)
                var_value=$(echo "$line" | cut -d'=' -f2-)
                echo "$var_name = $var_value"
            fi
        done < "$ENV_FILE"
    else
        echo "Environment file not found: $ENV_FILE"
    fi
}

# This will automatically load environment variables when this script is sourced
env_load
