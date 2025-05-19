from flask import Flask, request, jsonify
import whisper

model = whisper.load_model("small")  # or tiny, base...

app = Flask(__name__)

@app.route("/transcribe", methods=["POST"])
def transcribe():
    audio_file = request.files["file"]
    result = model.transcribe(audio_file)
    return jsonify(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5005)
