#!/bin/bash

# Define the array with lowercase extensions only
allowed_extensions=("jpg" "jpeg" "docx" "txt" "csv" "xlsx" "pdf" "pptx" "dwg" "xls" "dxf" "skp")
excluded_paths_omifa=("2013" "2014" "2015" "2016" "2017" "2018")

# Funcție pentru indexare fișier
indexFile() {
  local filePath="$1"
  local ext="$2"
  local path="$3"

  # Id unic bazat pe cale, fără slash-uri
  id=$(echo "$filePath" | tr -d '\\/ []%:?#[]@!$&()*+,;="%<>\^`{|}~')
  id=$(echo "$id" | tr -d "'")

  resp=$(base64 --wrap=0 "$filePath" |
    # into jq to make it a proper JSON string within the
    # JSON data structure
    jq --slurp --raw-input --arg FileName "$filePath" \
    '{
        "data": .,
        "filename": $FileName
    }' | 
    curl -s -X POST -d @- "http://192.168.1.251:9200/omifafiles/_doc/$id?pipeline=attachment" \
        -H "Content-Type: application/json" \
        -H "$authHeader"
    ) 
    
    if echo "$resp" | jq -e 'has("error")' > /dev/null; then
      echo "Failed to send data for $filePath, HTTP code: $resp" 
      echo "$filePath">> "failed_files_by_content.txt"
    else 
      echo "Data sent successfully for $filePath"
    fi
}

# Citire folder de la user
read -p "Introdu calea către folder sau fisier: " path
echo "" > "failed_files_by_content.txt"
respPipeline=$(curl -s -X PUT "http://192.168.1.251:9200/_ingest/pipeline/attachment-pipeline" \
     -H "Content-Type: application/json" \
     -d '{
     "description": "Extract attachment information and remove the source encoded data",
     "processors": [
        {
            "attachment": {
                "field": "data",
                "properties": [
                    "content",
                    "content_type",
                    "content_length"
                ]
            }
        },
        {
            "remove": {
                "field": "data"
            }
        }
    ]
}')
echo "Pipeline creation response: $respPipeline"

ext=$(echo "${path##*.}" | tr "[:upper:]" "[:lower:]")
if [[ " ${allowed_extensions[*]} " =~ " ${ext} " ]]; then
    echo "Indexare fișier: $path"
    indexFile "$path" "$ext"
    exit 1
fi

if [[ ! -d "$path" ]]; then
  echo "Calea nu există sau nu exista suport pentru extensia ta!" >&2
  exit 1
fi

# Build the find expression
find_expression=""
excluded_expression=""

for ext in "${allowed_extensions[@]}"; do
    # adaugăm o expresie -iname "*.ext"
    find_expression+=" -iname '*.${ext}' -o"
done

for excl in "${excluded_paths[@]}"; do
    # adaugăm o expresie -iname "*.ext"
    excluded_expression+=" -iname '${path}/${excl}' -o"
done

# scoatem ultimul -o
find_expression="${find_expression% -o}"
excluded_expression="${excluded_expression% -o}"

#index folders
folders=("$path/"*/)
for f in "${folders[@]}"; do
  foldername=$(basename "$f")
  if [[ ${excluded_paths[@]} = $foldername ]]
  then
    continue
  fi
  eval "find \"$f\" -type f \\( $find_expression \\)"  | while read -r file; do
    echo "Indexare fișier: $file"
    indexFile "$file" "$(echo "${file##*.}" | tr "[:upper:]" "[:lower:]")" "$path"
  done
done

echo "Indexing files from $path"

# index all the files with desired extension from the main folder folder 
eval "find \"$path\" -type f \\( $find_expression \\) -mindepth 1 -maxdepth 1" | while read -r file; do
  echo "Indexare fișier: $file"
  indexFile "$file" "$(echo "${file##*.}" | tr "[:upper:]" "[:lower:]")" "$path"
done


