#!/bin/bash

# Define the array with lowercase extensions only
allowed_extensions=("jpg" "jpeg" "docx" "txt" "csv" "xlsx" "pdf" "pptx" "dwg" "xls" "dxf" "skp")
excluded_paths_logistica=("V_ARHIVA_DOCUMENTE_VECHI" "VERSALOGIC_2024" "Wurth-LOGO" "BKP_MAIL" "Exporturi" "HyperBill" ".AppleDB" "#teste" "#recycle")
excluded_paths_omifa=("2013" "2014" "2015" "2016" "2017" "2018")

host="192.168.1.251"
# host="127.0.0.1" #for testing
index="omifalogistica"
# index="omifalogistica_test" #for testing

# Citire folder de la user
if [[ -z "$1" ]]; then
  read -p "Introdu calea către folder sau fisier: " path
else
  path="$1"
fi
date_str="$(date +%Y-%m-%d_%H:%M)"
script_dir="$(dirname "$(realpath "$0")")"
log_file="$script_dir/failed_only_location_${path##*/}_${date_str}.txt"

# Funcție pentru indexare fișier
indexFile() {
  local filePath="$1"
  local ext="$2"

  # Id unic bazat pe cale, fără slash-uri
  id=$(echo "$filePath" | tr -d '\\/ []%:?#[]@!$&()*+,;="%<>\^`{|}~')
  id=$(echo "$id" | tr -d "'")
  resp=$(curl -X POST -s "http://$host:9200/$index/_doc/$id" \
    -H "Content-Type: application/json" \
    -H "$authHeader" \
    -d "{ \"filename\": \"$filePath\", \"full_filename\": \"$filePath\", \"extension\": \"$ext\" }")

  if echo "$resp" | jq -e 'has("error")' > /dev/null; then
    echo "Failed to send data for $filePath, HTTP code: $resp" >> $log_file
  else 
    echo "Data sent successfully for $filePath"
  fi
}


ext=$(echo "${path##*.}" | tr "[:upper:]" "[:lower:]")
if [[ "${allowed_extensions[*]}" =~ "${ext}" ]]; then
    echo "Indexare fișier: $path"
    indexFile "$path" "$ext"
    exit 1
fi

if [[ ! -d "$path" ]]; then
  echo "Calea nu există sau nu exista suport pentru extensia ta!" >&2
  exit 1
fi

excluded_paths=()
# excluded_paths=${excluded_paths_logistica[@]} #for testing
if [ "$path" = "/volume1/OMIFA_FILESRV" ]; then
  excluded_paths=${excluded_paths_omifa[@]}
elif [ "$path" = "/volume1/LOGISTICA" ]; then
  excluded_paths=${excluded_paths_logistica[@]}
else 
  echo "Unrecognised path"
  exit 1 #comment this for testing
fi

# Build the find expression
find_expression=""

for ext in "${allowed_extensions[@]}"; do
    # adaugăm o expresie -iname "*.ext"
    find_expression+=" -iname '*.${ext}' -o"
done


# scoatem ultimul -o
find_expression="${find_expression% -o}"

#index folders
#get all folders from the path
folders=("$path/"*/)
# iterate thru them and skip them if they are excluded
for f in "${folders[@]}"; do
  foldername=$(basename "$f")
  if [[ $excluded_paths[@] =~ $foldername ]]
  then
    echo "excludem $foldername"
    continue
  fi
  # only index files with desired extension
  eval "find \"$f\" -type f \\( $find_expression \\)"  | while read -r file; do
    # echo "Indexare fișier: $file"
    indexFile "$file" "$(echo "${file##*.}" | tr "[:upper:]" "[:lower:]")" "$path"
  done
done

#index files
echo "Indexing files...."

# index all the files with desired extension from the main folder folder 
eval "find \"$path\" -type f \\( $find_expression \\) -mindepth 1 -maxdepth 1" | while read -r file; do
  # echo "Indexare fișier: $file"
  indexFile "$file" "$(echo "${file##*.}" | tr "[:upper:]" "[:lower:]")" "$path"
done
