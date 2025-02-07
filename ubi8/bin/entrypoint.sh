#!/bin/sh

AUDIO_FILES=${1:-/audio}
WHISPER_MODEL=${2:-tiny.en}

usage(){
  echo "
    This container processes audio files in the following path and model.
    You can override these variables:

      AUDIO_FILES: $AUDIO_FILES
      WHISPER_MODEL: $WHISPER_MODEL

    Example: podman run -it --rm -v $(pwd)/audio:/audio whisper
  "
}

# take the first parameter or default to /audio, then default the model to tiny.en if none passed
process_audio(){
  AUDIO_FILES=${1:-/audio}
  WHISPER_MODEL=${2:-tiny.en}

  whisper $AUDIO_FILES/* --model $WHISPER_MODEL
}

# if you pass parameter, it will execute as is, else run whisper --help
if [ "$1" != "" ]; then
  case "$1" in

    *) exec "$@";;
  esac
else
  usage
fi

