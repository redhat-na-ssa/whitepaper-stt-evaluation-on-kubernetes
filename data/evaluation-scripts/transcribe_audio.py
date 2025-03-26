import whisper
import os

def transcribe_audio(input_file, output_dir, model_dir, output_format='txt', language='en', task='transcribe'):
    """
    Transcribes an audio file using OpenAI's Whisper model.

    Parameters:
    - input_file (str): Path to the audio file.
    - output_dir (str): Directory where the transcription file will be saved.
    - model_dir (str): Directory to store/load the Whisper model.
    - output_format (str): Format of the output file (default: 'txt').
    - language (str): Language of the audio (default: 'en').
    - task (str): Task to perform ('transcribe' or 'translate').
    """
    # Load model from specified model directory
    model = whisper.load_model("large", download_root=model_dir)
    
    # Transcribe audio
    result = model.transcribe(input_file, language=language)
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Define output file path
    output_file = os.path.join(output_dir, os.path.splitext(os.path.basename(input_file))[0] + f'.{output_format}')
    
    # Save the transcription
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(result['text'])
    
    print(f"Transcription saved to {output_file}")

# Example usage
if __name__ == "__main__":
    transcribe_audio(
        input_file="input-samples/harvard.wav",
        output_dir="/tmp/",
        model_dir="/tmp/",
        output_format="txt",
        language="en",
        task="transcribe"
    )
