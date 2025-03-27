import whisper
import os
import logging

logger = logging.getLogger()

def transcribe_audio(model, input_file, output_dir, model_name, model_dir, output_format='txt', language='en', task='transcribe'):
    """
    Transcribes an audio file using OpenAI's Whisper model.

    Parameters:
    - model (str): Name of the model being tested (i.e. whisper)
    - input_file (str): Path to the audio file.
    - output_dir (str): Directory where the transcription file will be saved.
    - model_name (str): Sub-Name/tag of the model (i.e. tiny.en)
    - model_dir (str): Directory to store/load the Whisper model.
    - output_format (str): Format of the output file (default: 'txt').
    - language (str): Language of the audio (default: 'en').
    - task (str): Task to perform ('transcribe' or 'translate').
    """

    logger.debug(f'transcribe_audio(): model = {model}')
    logger.debug(f'transcribe_audio(): model_name = {model_name}')

    # Load model from specified model directory
    # model = whisper.load_model("large", download_root=model_dir)
    model = whisper.load_model(model_name, download_root=model_dir)

    
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
