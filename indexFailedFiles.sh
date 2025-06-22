#!/bin/bash

read -p "Introdu calea către fisierul cu path-urile esuate: " path

#try to index failed files only by location
while IFS= read -r filepath; do
    echo "$filepath"
    # Ignoră liniile goale și comentariile
    if [[ -z "$filepath" ]]; then
        continue
    fi
    
    # Apelează scriptul cu mai mulți parametri
    ./indexOnlyLocation.sh "$filepath"
done < "$path"

