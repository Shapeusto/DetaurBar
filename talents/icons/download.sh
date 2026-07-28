#!/bin/bash

# Názov vstupného HTML súboru
INPUT_FILE="talent_tree.html"
# Priečinok, do ktorého sa uložia stiahnuté ikony
OUTPUT_DIR="stiahnute_ikony"

# Skontroluj, či existuje vstupný súbor
if [ ! -f "$INPUT_FILE" ]; then
    echo "Chyba: Súbor $INPUT_FILE neexistuje!"
    exit 1
fi

# Vytvor priečinok na ikony, ak neexistuje
mkdir -p "$OUTPUT_DIR"

echo "=== Začínam extrahovať a sťahovať ikony ==="

# 1. Extrahuj URL adresy z background:url(...)
# 2. Pridaj protokol 'https:' ak chýba (keďže v HTML je len //cdn.warmane...)
# 3. Odstráň duplicity (rovnaké ikony sa stiahnu iba raz)
grep -o 'background:url([^)]*)' "$INPUT_FILE" | \
sed -e 's/background:url(//' -e 's/)//' -e 's/;//' | \
sort -u | \
while read -r url; do

    # Ak URL začína s //, pridaj https:
    if [[ $url == //* ]]; then
        full_url="https:${url}"
    else
        full_url="$url"
    fi

    # Získaj názov súboru z URL (napr. spell_nature_wispsplode.jpg)
    filename=$(basename "$url")

    echo "Sťahujem: $filename ..."
    
    # Stiahnutie súboru pomocou curl do cieľového priečinka
    curl -s "$full_url" -o "$OUTPUT_DIR/$filename"
done

echo "=== Hotovo! Všetky ikony nájdeš v priečinku '$OUTPUT_DIR' ==="