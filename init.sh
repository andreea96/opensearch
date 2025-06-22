curl --location --request PUT 'http://opensearch:9200/_ingest/pipeline/attachment' \
--header 'Content-Type: application/json' \
--data '{
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
}'

curl --location --request PUT 'http://opensearch:9200/omifalogistica/' \
        --header 'Content-Type: application/json' \
        --data '{
        "settings": {
            "analysis": {
            "filter": {
                "image_ext_synonyms": {
                "type": "synonym",
                "synonyms": [
                    "jpeg => jpg"
                ]
                }
            },
            "tokenizer": {
                "custom_pattern_tokenizer": {
                "type": "pattern",
                "pattern": "[\\W_]+"
                }
            },
            "analyzer": {
                "custom_text_analyzer": {
                "type": "custom",
                "tokenizer": "custom_pattern_tokenizer",
                "filter": [
                    "lowercase",
                    "image_ext_synonyms"
                ]
                }
            },
            "fields": {
                "raw": {
                    "type": "keyword"
                }
            }
            }
        },
        "mappings": {
            "properties": {
            "filename": {
                "type": "text",
                "analyzer": "custom_text_analyzer"
            }
            }
        }
        }
        '
curl --location --request PUT 'http://opensearch:9200/omifafiles/' \
        --header 'Content-Type: application/json' \
        --data '{
        "settings": {
            "analysis": {
            "filter": {
                "image_ext_synonyms": {
                "type": "synonym",
                "synonyms": [
                    "jpeg => jpg"
                ]
                }
            },
            "tokenizer": {
                "custom_pattern_tokenizer": {
                "type": "pattern",
                "pattern": "[\\W_]+"
                }
            },
            "analyzer": {
                "custom_text_analyzer": {
                "type": "custom",
                "tokenizer": "custom_pattern_tokenizer",
                "filter": [
                    "lowercase",
                    "image_ext_synonyms"
                ]
                }
            },
            "fields": {
                "raw": {
                    "type": "keyword"
                }
            }
            }
        },
        "mappings": {
            "properties": {
            "filename": {
                "type": "text",
                "analyzer": "custom_text_analyzer"
            }
            }
        }
        }
        '
