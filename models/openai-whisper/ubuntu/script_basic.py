import whisper

model = whisper.load_model("turbo")
result = model.transcribe("audio/jfk-audio-inaugural-ddress-20-january-1961.mp3")
print(result["text"])