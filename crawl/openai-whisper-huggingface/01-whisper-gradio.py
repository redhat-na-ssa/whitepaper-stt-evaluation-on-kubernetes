# https://www.gradio.app/guides/real-time-speech-recognition
import gradio as gr
from transformers import pipeline
import numpy as np

OPENSHIFT=True

transcriber = pipeline("automatic-speech-recognition", model="openai/whisper-base.en")

def transcribe(audio):
    sr, y = audio
    
    # Convert to mono if stereo
    if y.ndim > 1:
        y = y.mean(axis=1)
        
    y = y.astype(np.float32)
    y /= np.max(np.abs(y))

    return transcriber({"sampling_rate": sr, "raw": y})["text"]  

demo = gr.Interface(
    transcribe,
    gr.Audio(sources="microphone"),
    "text",
)

if OPENSHIFT==True:
    demo.launch(server_name="0.0.0.0", server_port=8080)
else:
    demo.launch(server_name="0.0.0.0", server_port=8080, ssl_certfile="cert.pem",
        ssl_keyfile="key.pem", ssl_verify=False)


