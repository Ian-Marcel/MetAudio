#!/usr/bin/env bash

echo '- AUDIOEXIF SWISS-KNIFE - MULTIPLE ARTISTS  -------------------------'
for TRACK in "${TRACKS[@]}"; do
    # Variáveis de pré-operação.
    EXTENSION="${TRACK##*.}"   # Pega a extensão do arquivo.
    EXTENSION="${EXTENSION,,}" # Deixa ela em caixa baixa.
    # Variáveis de nomenclatura.
    TRACK_FILE=$(echo "$TRACK" | rev | cut -d '/' -f 1 | rev)
    TRACK_FOLDER=$(echo "$TRACK" | rev | cut -d '/' -f 2 | rev)
    TRACK_PATH=$(echo "$TRACK" | rev | cut -d '/' -f 2- | rev)
    OLD_TRACK_PATH=${OLD_TRACK_PATH:-$TRACK_PATH}
    echo "Editing file: $TRACK_FOLDER/$TRACK_FILE"
    if [[ "$EXTENSION" != "flac" ]]; then # Pula se a extensão não está na lista.
        echo "[WARN]: Improper file extension! MULTIPLE ARTISTS  only supports flac files."
        echo "[SKIP]"
        continue
    fi
    # Variáveis de pesquisas.
    ARTIST_TAG_COUNT=$(metaflac --show-tag=ARTIST{,S} "$TRACK" | grep -inc ARTIST)                        # Procura a quantidade de tags 'ARTIST' na música.
    FAKE_LONE_ARTIST_TAG=$(metaflac --show-tag=ARTIST "$TRACK" | grep -o ',')                             # Procura a divisoria (linha), pois se existir, provavelmente existe mais de um artista.
    POSITIVE_TAGS=$(metaflac --show-tag={ALBUMARTIST,ARTISTS} "$TRACK")                                   # Procura pelas mesmas tags que serão adicionadas, pois se existir, da pra pular a edição do arquivo atual.
    ALL_ARTISTS=$(metaflac --show-tag=ARTIST "$TRACK" | sed 's/^[^=]*=//' | sed -E 's/\s+feat\.?\s+/,/g') # Coleta todos o artistas da música.
    TRACK_ALBUMARTIST=$(metaflac --show-tag=ALBUMARTIST "$TRACK")                                         # Procura pela tag ALBUMARTIST, para se caso não haja, seja adicionado com o valor de $ALBUMARTIST.
    # Variáveis de coleta e organização.
    IFS=',' read -ra ARTISTS <<<"$ALL_ARTISTS"                 # Separa todos os artistas divididos entre linhas e cria uma lista deles com cada um sendo uma array.
    ORIGINAL_ARTIST=${ARTISTS[0]}                              # Artista principal, o primeiro nomeado na música.
    ORIGINAL_ARTIST=$(echo "$ORIGINAL_ARTIST" | sed 's/^ *//') # Remove qualquer espaço no começo do valor do $ORIGINAL_ARTIST.
    if [[ "$TRACK_PATH" != "$OLD_TRACK_PATH" ]]; then
        ALBUMARTIST=$ORIGINAL_ARTIST
        OLD_TRACK_PATH=$TRACK_PATH
    else
        ALBUMARTIST=${ALBUMARTIST:-$ORIGINAL_ARTIST} # Preserva o valor de $ALBUMARTIST se já estiver definido; caso contrário, usa $ORIGINAL_ARTIST.
    fi
    echo "Contains: $ARTIST_TAG_COUNT artist(s) tag"
    if [ "$ARTIST_TAG_COUNT" -eq 1 ] && [ -z "$FAKE_LONE_ARTIST_TAG" ]; then
        echo "[SKIP]"
        continue
    elif [[ -n "$POSITIVE_TAGS" ]]; then
        echo "[WARN] Already with correct tags:"
        echo -e "$POSITIVE_TAGS\n"
        echo "[SKIP]"
        continue
    else
        echo "But the tag contains more than one artist."
    fi
    if [ -z "$TRACK_ALBUMARTIST" ]; then
        metaflac --set-tag=ALBUMARTIST="$ALBUMARTIST" "$TRACK"
    fi
    for ARTIST in "${ARTISTS[@]}"; do
        ARTIST="$(echo "$ARTIST" | sed 's/^ *//')" # Remove qualquer espaço no começo do valor do $ARTIST
        echo "Adding $ARTIST to $TRACK_FOLDER/$TRACK_FILE"
        metaflac --set-tag=ARTISTS="$ARTIST" "$TRACK"
    done
done
echo '- Done! -------------------------------------------------------'
