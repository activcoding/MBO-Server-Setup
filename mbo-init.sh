#!/bin/bash

# Colors
RED='\033[0;31m'
ORANGE='\033[0;33m'
green_color="\033[32m"
NC='\033[0m' # No Color

# Symbols
dot="\u00B7"
checkmark="\xE2\x9C\x94"
cross="\xE2\x9C\x96"
cross_mark="✗"

missing_folders=()
missing_env_vars=()
firebase_admin_json_exists=false
docker_compose_yml_exists=false
docker_is_installed=false
data_folder_exists=false
mongo_init_js_exists=false
mongo_init_js_correct=false

# Function to check if a folder exists
check_folder() {
    if [ ! -d "$1" ]; then
        missing_folders+=("$1")
    fi
}

# Function to check if a file exists
check_file() {
    local file_to_check="$1"
    local var_to_set="$2"

    if [ -f "$file_to_check" ]; then
        eval "$var_to_set=true"
    fi
}

check_if_data_folder_exists() {
    if [ ! -d "data" ]; then
        read -p "The 'data' folder is missing. Do you want to create it? (y/N): " create_data_folder
        if [ "$create_data_folder" = "y" ]; then
            mkdir data
            data_folder_exists=true
        else 
            data_folder_exists=false
        fi
    else 
        data_folder_exists=true
    fi
}

# Function to check if an environment variable is set
check_env_variable() {
    if [ -z "${!1}" ]; then
        missing_env_vars+=("$1")
    fi
}

check_docker_installed() {
    if command -v docker &> /dev/null; then
        docker_is_installed="true"
    else
        docker_is_installed="false"
    fi
}

download_docker() {
    # Download Docker
    echo "Downloading Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh

    # Install Docker
    echo "Installing Docker..."
    sudo sh get-docker.sh

    # Clean up
    rm get-docker.sh

    # Verify installation
    if command -v docker &> /dev/null; then
        echo "Docker has been installed successfully."
        return 0
    else
        echo "Failed to install Docker."
        return 1
    fi
}

# Function to set environment variables in .env file
set_env_variables() {
    # Check if .env file exists
    if [  ! -f .env ]; then
        echo ".env file does not exist. Creating a new one."
        touch .env
    fi

    read -p "Do you want to set environment variables now? (y/N): " set_vars
    if [ "$set_vars" != "y" ]; then
        echo "Operation aborted."
        return 1
    fi

    # Array of environment variables
    env_variables=("MONGO_INITDB_DATABASE" "MONGODB_INITDB_ROOT_USERNAME" "MONGODB_INITDB_ROOT_PASSWORD" "JWT_SECRET")

    # Loop through environment variables and set values
    for var in "${env_variables[@]}"; do
        read -p "Enter value for $var: " value
        echo "$var=$value" >> .env
    done

    echo "Environment variables have been set."
}

# Function to remove whitespace characters from a string
remove_whitespace() {
    echo "$1" | tr -d '[:space:]'
}

# Function to check if 'mongo-init.js' exists and contains specified contents
check_init_mongo() {
    local file="mongo-init.js"
    local contents="db.createUser({user: process.env.MONGODB_INITDB_ROOT_USERNAME,pwd: process.env.MONGODB_INITDB_ROOT_PASSWORD,roles: [{role: \"readWrite\",db: process.env.MONGO_INITDB_DATABASE}]});
"

    if [ -f "$file" ]; then
     local file_contents=$(cat "$file")
        local stripped_file_contents=$(remove_whitespace "$file_contents")
        local stripped_contents=$(remove_whitespace "$contents")
        
        if [ "$stripped_file_contents" = "$stripped_contents" ]; then
            mongo_init_js_exists=true
            mongo_init_js_correct=true
            return 0
        else
             read -p "Do you want to overwrite '$file' with the correct contents? (y/N): " overwrite_file
            if [ "$overwrite_file" == "y" ]; then
                echo "$contents" > "$file"
                echo "'$file' overwritten with the correct contents."
                mongo_init_js_exists=true
                mongo_init_js_correct=true
                return 0
            else
                mongo_init_js_exists=true
                mongo_init_js_correct=false
                return 1
            fi
        fi
    else
        echo "'$file' does not exist."
        read -p "Do you want to create '$file' with the correct contents? (y/N): " create_file
        if [ "$create_file" == "y" ]; then
            echo "$contents" > "$file"
            echo "'$file' created with the correct contents."
            mongo_init_js_exists=true
            mongo_init_js_correct=true
            return 0
        else
            mongo_init_js_exists=false
            mongo_init_js_correct=false
            return 1
        fi
    fi
}
# Function to validate content of firebase-admin.json
validate_firebase_admin_json() {
    local json_file="$1"
    check_file "firebase-admin.json" "firebase_admin_json_exists"
    if [ "$firebase_admin_json_exists" = false ]; then
        return
    fi
    local required_keys=(
        "type"
        "project_id"
        "private_key_id"
        "private_key"
        "client_email"
        "client_id"
        "auth_uri"
        "token_uri"
        "auth_provider_x509_cert_url"
        "client_x509_cert_url"
        "universe_domain"
    )

    for key in "${required_keys[@]}"; do
        if ! grep -q "\"$key\"" "$json_file"; then
            echo "Error: Key '$key' is missing in firebase-admin.json."
            return
        fi
    done
}

# Load environment variables from .env file
[ -f .env ] && source .env

check_docker_installed
check_file "docker-compose.yml" "docker_compose_yml_exists"
validate_firebase_admin_json "firebase-admin.json"
check_init_mongo
check_if_data_folder_exists

if [ "$docker_is_installed" = false ]; then
    read -p "${ORANGE}[!]${NC} Docker isn't installed. Do you want to install Docker? (y/N): " install_docker
    if [ "$install_docker" = "y" ]; then
        download_docker
    fi
fi

check_folder "Vertretungen"
check_folder "Vertretungen/Schueler"
check_folder "Vertretungen/Lehrer"
for folder in "heute" "morgen" "Informationen"; do
    check_folder "Vertretungen/Schueler/$folder"
done
for folder in "heute" "morgen" "Informationen"; do
    check_folder "Vertretungen/Lehrer/$folder"
done

# If there are missing folders, prompt the user to create them
if [ ${#missing_folders[@]} -gt 0 ]; then
    echo "The Vertretungs-folder structure is missing or incorect:"
    for folder in "${missing_folders[@]}"; do
        echo "$folder"
    done
    echo
    read -p "Do you want to create missing folders? (y/N): " create_folders

    if [ "$create_folders" == "y" ]; then
        for folder in "${missing_folders[@]}"; do
            mkdir -p "$folder"
            echo "Folder '$folder' created."
        done

        missing_folders=()
    else
        echo -e "${ORANGE}[!]${NC} Please create those folders yourself or use a symbolic link"
        sleep 0.3
    fi
fi

# Check required environment variables
check_env_variable "MONGO_INITDB_DATABASE"
check_env_variable "MONGODB_INITDB_ROOT_USERNAME"
check_env_variable "MONGODB_INITDB_ROOT_PASSWORD"
check_env_variable "JWT_SECRET"

if [ ${#missing_env_vars[@]} -gt 0 ]; then
    set_env_variables
    # Check env again after setting variables
    missing_env_vars=()
    # Load environment variables from .env file
    [ -f .env ] && source .env
    check_env_variable "MONGO_INITDB_DATABASE"
    check_env_variable "MONGODB_INITDB_ROOT_USERNAME"
    check_env_variable "MONGODB_INITDB_ROOT_PASSWORD"
    check_env_variable "JWT_SECRET"
fi

echo #empty line
echo #empty line

# If there are missing environment variables, inform the user to create a .env file
if [ ${#missing_env_vars[@]} -gt 0 ]; then
    echo -e "${ORANGE}[!]${NC} The following environment variables are missing:"
    for var in "${missing_env_vars[@]}"; do
        echo "$var"
    done
    echo
    echo -e "${RED}[$cross_mark]${NC} Please create a '.env' file in the current folder and include the following missing variables"
else 
    echo -e "${green_color}[$checkmark]${NC} All required environment variables are set."
fi

if [ ${#missing_folders[@]} -gt 0 ]; then
    echo -e "${RED}[$cross_mark]${NC} The folder Vertretungen or one of it's subfolders is missing. Please rerun the script and let it create the folders for you."
else 
    echo -e "${green_color}[$checkmark]${NC} All required folders are present."
fi

if [ "$firebase_admin_json_exists" = false ]; then
    echo -e "${RED}[$cross_mark]${NC} The 'firebase-admin.json' file is missing or incomplete. Follow the instructions in the README to create the file."
else 
    echo -e "${green_color}[$checkmark]${NC} The 'firebase-admin.json' file is present and valid."
fi

if [ "$data_folder_exists" = false ]; then
    echo -e "${RED}[$cross_mark]${NC} The 'data' folder is missing. Rerun the script to create the folder."
else 
    echo -e "${green_color}[$checkmark]${NC} The 'data' folder is present."
fi

if [ "$mongo_init_js_exists" = false ]; then
    echo -e "${RED}[$cross_mark]${NC} The 'mongo-init.js' file is missing. Rerun the script to create the file."
else 
    echo -e "${green_color}[$checkmark]${NC} The 'mongo-init.js' file is present."
fi

if [ "$mongo_init_js_correct" = false ]; then
    echo -e "${RED}[$cross_mark]${NC} The 'mongo-init.js' file is incorrect. Rerun the script to override the current file."
else 
    echo -e "${green_color}[$checkmark]${NC} The 'mongo-init.js' file is correct."
fi

if [ "$docker_is_installed" = false ]; then
    echo -e "${RED}[$cross_mark]${NC} Docker isn't installed."
else
    echo -e "${green_color}[$checkmark]${NC} Docker is installed."
fi

if [ "$docker_compose_yml_exists" = false ]; then
    echo -e "${RED}[$cross_mark]${NC} The 'docker-compose.yml' file is missing. Follow the instructions in the README to create the file."
else 
    echo -e "${green_color}[$checkmark]${NC} The 'docker-compose.yml' file is present."
fi