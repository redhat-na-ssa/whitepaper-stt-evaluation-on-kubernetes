#!/bin/sh

AUDIO_FILES=${AUDIO_FILES:-/data/audio-samples}
WHISPER_MODEL=${WHISPER_MODEL:-tiny.en}
MODEL_CACHE=${MODEL_CACHE:-/data/models}
XDG_CACHE_HOME=${MODEL_CACHE}

export XDG_CACHE_HOME

init(){
  [ -e "${MODEL_CACHE}" ] || mkdir -p "${MODEL_CACHE}"
  [ -e "${AUDIO_FILES}" ] || mkdir -p "${AUDIO_FILES}"
  . /data/venv/bin/activate
}

usage(){
  echo "
    This container processes audio files in the following path and model.
    
    You can override these (default) environment variables:
      AUDIO_FILES:   $AUDIO_FILES
      MODEL_CACHE:   $MODEL_CACHE
      WHISPER_MODEL: $WHISPER_MODEL

    Example (interactive): 
      podman run -it --rm -v \$(pwd)/scratch:/data:z whisper:ubuntu /bin/sh

    Example (batch):
      podman run -it --rm -v \$(pwd)/scratch:/data:z whisper:ubuntu process_audio

    Example (download file):
      podman run -it --rm whisper:ubuntu process_url <url>
  
    Print model list:
      podman run -it --rm -v \$(pwd)/scratch:/data:z whisper:ubuntu list_models

      python3 -c 'import whisper,pprint; pprint.pprint(whisper._MODELS)'
  "
}

list_models(){
  echo "
    Model List:
  "
  python3 -c 'import whisper,pprint; pprint.pprint(whisper._MODELS)'
}

process_url(){
  URL=${1}

  [ -z "${URL}" ] && return 1
  curl -sL "${URL}" -o "$AUDIO_FILES/output.mp4" || return 1
}

# take the first parameter or default to /audio, then default the model to tiny.en if none passed
process_audio(){
  WHISPER_MODEL=${1:-tiny.en}
  AUDIO_FILES=${2:-/data/audio}

  echo "
    WHISPER_MODEL: $WHISPER_MODEL
    AUDIO_FILES: $AUDIO_FILES
  "

  whisper \
    --model "$WHISPER_MODEL" \
    "$AUDIO_FILES"/*
}

init

# if you pass parameter, it will execute as is, else run whisper --help
if [ "$1" != "" ]; then
  case "$1" in
    process_audio) process_audio "$2" "$3" ;;
    process_url) process_url "$2" && process_audio "$3" ;;
    list_models) list_models ;;
    *) exec "$@";;
  esac
else
  usage
fi

