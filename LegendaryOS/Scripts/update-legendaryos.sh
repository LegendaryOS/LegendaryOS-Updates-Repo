#!/bin/bash
#!/bin/bash

# Ścieżka do pliku z wersją systemu
LOCAL_VERSION_FILE="/usr/share/LegendaryOS/version.txt"
REPO_URL="https://github.com/LegendaryOS/LegendaryOS-Updates-Repo.git"
RELEASES_API="https://api.github.com/repos/LegendaryOS/LegendaryOS-Updates-Repo/releases/latest"
TMP_DIR="/tmp/LegendaryOS-Updates-Repo"

# Pobranie lokalnej wersji
if [[ ! -f "$LOCAL_VERSION_FILE" ]]; then
    echo "Brak pliku $LOCAL_VERSION_FILE"
    exit 1
fi
LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | tr -d '[:space:]')

echo "Lokalna wersja: $LOCAL_VERSION"

# Pobranie najnowszej wersji z GitHub API
LATEST_VERSION=$(curl -s "$RELEASES_API" | grep -oP '"tag_name": "\K(.*)(?=")')

if [[ -z "$LATEST_VERSION" ]]; then
    echo "Nie udało się pobrać najnowszej wersji z GitHuba!"
    exit 1
fi

echo "Najnowsza wersja dostępna na GitHubie: $LATEST_VERSION"

# Porównanie wersji
if [[ "$LOCAL_VERSION" == "$LATEST_VERSION" ]]; then
    echo "System jest aktualny!"
    exit 0
else
    echo "Znaleziono nową wersję: $LATEST_VERSION"
    echo "Aktualizacja systemu..."

    # Usunięcie starego katalogu jeśli istnieje
    rm -rf "$TMP_DIR"

    # Klonowanie repo
    git clone "$REPO_URL" "$TMP_DIR"

    if [[ $? -ne 0 ]]; then
        echo "Błąd podczas klonowania repozytorium!"
        exit 1
    fi

    # Uruchomienie update script
    sudo chmod a+x /tmp/LegendaryOS-Updates-Repo/unpack.sh
    if [[ -f "$TMP_DIR/update.sh" ]]; then
        chmod +x "$TMP_DIR/update.sh"
        "$TMP_DIR/update.sh"
    else
        echo "Brak pliku update.sh w repozytorium!"
        exit 1
    fi
fi
