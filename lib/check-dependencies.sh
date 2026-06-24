if ! command -v ffmpeg >/dev/null 2>&1; then
    echo -e "[ WARN ] ffmpeg wasn't found, attempting to install it."
    sudo apt update 2>/dev/null && sudo apt install -y ffmpeg 2>/dev/null ||
        sudo dnf install -y --quiet ffmpeg 2>/dev/null ||
        sudo pacman -Sy --noconfirm --quiet ffmpeg 2>/dev/null
    if [ $? -gt 1 ]; then
        echo "Failed to install ffmpeg. Exiting"
        exit 2
    fi
fi
if ! command -v metaflac >/dev/null 2>&1; then
    echo -e "[ WARN ] metaflac wasn't found, attempting to install it."
    sudo apt-get update 2>/dev/null && sudo apt-get install -y flac 2>/dev/null ||
        sudo dnf install -y --quiet flac 2>/dev/null ||
        sudo pacman -Sy --noconfirm --quiet flac 2>/dev/null
    if [ $? -gt 1 ]; then
        echo "Failed to install metaflac. Exiting"
        exit 2
    fi
fi
if ! command -v exiftool >/dev/null 2>&1; then
    echo -e "[ WARN ] exiftool wasn't found, attempting to install it."
    sudo apt-get update 2>/dev/null && sudo apt-get install -y exiftool 2>/dev/null ||
        sudo dnf install -y --quiet exiftool 2>/dev/null ||
        sudo pacman -Sy --noconfirm --quiet exiftool 2>/dev/null
    if [ $? -gt 1 ]; then
        echo "Failed to install exiftool. Exiting"
        exit 2
    fi
fi
