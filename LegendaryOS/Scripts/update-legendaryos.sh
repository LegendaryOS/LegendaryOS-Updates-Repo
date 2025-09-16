#!/bin/bash

# ANSI color codes
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Ścieżki i URL-e
LOCAL_VERSION_FILE="/usr/share/LegendaryOS/version.txt"
REPO_URL="https://github.com/LegendaryOS/LegendaryOS-Updates-Repo.git"
RELEASES_API="https://api.github.com/repos/LegendaryOS/LegendaryOS-Updates-Repo/releases/latest"
TMP_DIR="/tmp/LegendaryOS-Updates-Repo"

# Funkcja spinnera z ulepszoną animacją
spinner() {
    local pid=$1
    local delay=0.05
    local spinstr='⣾⣷⣶⣴⣲⣰⣠⡀'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf "${CYAN} [%c] ${NC}" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Funkcja wyświetlania wiadomości z kolorami
print_message() {
    local type=$1
    local message=$2
    case $type in
        "INFO") echo -e "${BLUE}ℹ [INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}✓ [SUCCESS]${NC} $message" ;;
        "ERROR") echo -e "${RED}✗ [ERROR]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}⚠ [WARNING]${NC} $message" ;;
    esac
}

# Funkcja rysowania ramki
print_border() {
    echo -e "${MAGENTA}┌────────────────────────────────────────────────┐${NC}"
}

print_footer() {
    echo -e "${MAGENTA}└────────────────────────────────────────────────┘${NC}"
}

# Nagłówek
clear
print_border
echo -e "${WHITE}         LegendaryOS Update Script               ${NC}"
print_border

# Pobranie lokalnej wersji
print_message "INFO" "Checking local system version..."
if [[ ! -f "$LOCAL_VERSION_FILE" ]]; then
    print_message "ERROR" "Version file $LOCAL_VERSION_FILE not found!"
    print_footer
    exit 1
fi
LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | tr -d '[:space:]')
print_message "SUCCESS" "Local version: $LOCAL_VERSION"

# Pobranie najnowszej wersji z GitHub API
print_message "INFO" "Fetching latest version from GitHub..."
LATEST_VERSION=$(curl -s "$RELEASES_API" | grep -oP '"tag_name": "\K(.*)(?=")')
if [[ -z "$LATEST_VERSION" ]]; then
    print_message "ERROR" "Failed to retrieve latest version from GitHub!"
    print_footer
    exit 1
fi
print_message "SUCCESS" "Latest available version: $LATEST_VERSION"

# Porównanie wersji
if [[ "$LOCAL_VERSION" == "$LATEST_VERSION" ]]; then
    print_message "SUCCESS" "System is up to date! 🎉"
    print_footer
    exit 0
else
    print_message "WARNING" "New version found: $LATEST_VERSION"
    print_message "INFO" "Starting system update process..."

    # Usunięcie starego katalogu
    print_message "INFO" "Removing old temporary directory..."
    rm -rf "$TMP_DIR" &>/dev/null
    print_message "SUCCESS" "Old directory removed successfully."

    # Klonowanie repozytorium
    print_message "INFO" "Cloning update repository..."
    git clone "$REPO_URL" "$TMP_DIR" &>/dev/null &
    spinner $!
    if [[ $? -ne 0 ]]; then
        print_message "ERROR" "Failed to clone repository!"
        print_footer
        exit 1
    fi
    print_message "SUCCESS" "Repository cloned successfully."

    # Nadanie uprawnień i uruchomienie skryptu aktualizacji
    print_message "INFO" "Preparing update scripts..."
    if [[ -f "$TMP_DIR/unpack.sh" ]]; then
        sudo chmod +x "$TMP_DIR/unpack.sh"
    else
        print_message "ERROR" "unpack.sh not found in repository!"
        print_footer
        exit 1
    fi
    if [[ -f "$TMP_DIR/update.sh" ]]; then
        chmod +x "$TMP_DIR/update.sh"
        print_message "INFO" "Executing update script..."
        "$TMP_DIR/update.sh"
        print_message "SUCCESS" "Update completed successfully! 🚀"
    else
        print_message "ERROR" "update.sh not found in repository!"
        print_footer
        exit 1
    fi
fi

print_border
echo -e "${GREEN}        System Update Process Completed!         ${NC}"
print_border
