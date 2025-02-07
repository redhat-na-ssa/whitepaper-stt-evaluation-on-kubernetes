#!/bin/sh

AUDIO_FILES=${AUDIO_FILES:-/data/audio}
WHISPER_MODEL=${WHISPER_MODEL:-tiny.en}
MODEL_CACHE=${MODEL_CACHE:-/data/models}
XDG_CACHE_HOME=${MODEL_CACHE}

export XDG_CACHE_HOME

init(){
  [ -e "${XDG_CACHE_HOME}" ] || mkdir -p "${XDG_CACHE_HOME}"
}

usage(){
  echo "
    This container processes audio files in the following path and model.
    
    You can override these (default) environment variables:
      AUDIO_FILES:   $AUDIO_FILES
      MODEL_CACHE:   $MODEL_CACHE
      WHISPER_MODEL: $WHISPER_MODEL

    Example (interactive): 
      podman run -it --rm -v \$(pwd)/scratch:/data:z whisper:ubi /bin/sh

    Example (batch):
      podman run -it --rm -v \$(pwd)/scratch:/data:z whisper:ubi process_audio
  
    Print model list:
      podman run -it --rm -v \$(pwd)/scratch:/data:z whisper:ubi list_models

      python3 -c 'import whisper,pprint; pprint.pprint(whisper._MODELS)'
  "
}

list_models(){
  echo "
    Model List:
  "
  python3 -c 'import whisper,pprint; pprint.pprint(whisper._MODELS)'
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
    --model $WHISPER_MODEL \
    $AUDIO_FILES/*
}

init

# if you pass parameter, it will execute as is, else run whisper --help
if [ "$1" != "" ]; then
  case "$1" in
    process_audio) process_audio "$2" "$3";;
    list_models) list_models ;;
    *) exec "$@";;
  esac
else
  usage
fi

