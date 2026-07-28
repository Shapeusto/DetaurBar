#!/bin/bash

VstupnySubor="talenty.txt"

# Skontrolujeme, či súbor existuje
if [ ! -f "$VstupnySubor" ]; then
    echo "Chyba: Súbor '$VstupnySubor' neexistuje!"
    exit 1
fi

echo "Sťahujem názvy talentov z WoWHead (WotLK Databáza)..."
echo "------------------------------------------------------------------"
printf "%-10s | %-7s | %s\n" "ID" "Body" "Názov talentu"
echo "------------------------------------------------------------------"

# Čítanie súboru riadok po riadku
while IFS= read -r riadok || [ -n "$riadok" ]; do
    # Odstránime prípadné biele znaky (napr. Windows konce riadkov CRLF)
    riadok=$(echo "$riadok" | tr -d '\r' | xargs)

    # Preskočíme prázdne riadky
    [ -z "$riadok" ] && continue

    # Rozdelíme riadok pomocou dvojbodky ako oddeľovača
    spell_id=$(echo "$riadok" | cut -d':' -f1 | xargs)
    points=$(echo "$riadok" | cut -d':' -f2 | xargs)

    # Ak máme číselné ID a body, ideme na API
    if [[ "$spell_id" =~ ^[0-9]+$ ]] && [ -n "$points" ]; then
        
        # Voláme WotLK subdoménu s JSON tooltipom
        json_response=$(curl -s "https://nether.wowhead.com/wotlk/tooltip/spell/${spell_id}")
        
        # Vytiahneme názov ("name":"Názov talentu") pomocou interného Bash regexu
        spell_name=""
        if [[ $json_response =~ \"name\":\"([^\"]+)\" ]]; then
            spell_name="${BASH_REMATCH[1]}"
        fi

        # Ak by predsa len API nič nevrátilo
        if [ -z "$spell_name" ]; then
            spell_name="Neznámy spell (ID: ${spell_id})"
        fi

        # Výpis do konzoly
        printf "%-10s | %-7s | %s\n" "$spell_id" "$points" "$spell_name"
        
        # Malá pauza medzi požiadavkami (0.05 sekundy)
        sleep 0.05
    fi
done < "$VstupnySubor"

echo "------------------------------------------------------------------"