# LLM Analyzer

python3 -m pip install transformers

python3 -m pip install torch

## Reinstall compatible versions (CPU-only)
If you're running CPU-only:
`pip install torch torchvision`

If you're using GPU (e.g. with CUDA 11.8):
`pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118`

Install accelerate library
`pip install accelerate`

Upgrade jinja2
`pip install --user --upgrade "jinja2>=3.1.0"`

Install pandas
`pip3 install --user pandas`

## Verify Install
To double check that torchvision::nms exists:
`python3 -c "import torchvision.ops; print(hasattr(torchvision.ops, 'nms'))"`

python3 install_granite_model.py

Read the CSV File: Use Python's pandas library to load your CSV data.​

```python
python3
```

Read the CSV File: Use Python's pandas library to load your CSV data.​

```python
import pandas as pd

df = pd.read_csv('../data/metrics/aiml_functional_metrics.csv')

df.head()
```

Prepare Prompts: Iterate over the DataFrame rows and create prompts that include the relevant data.​

```python
prompts = []
for index, row in df.iterrows():
    prompt = f"Analyze the following data: {row.to_dict()}"
    prompts.append(prompt)
```

Generate Responses: Use the model to generate responses for each prompt.​

```python
for prompt in prompts:
    conv = [{"role": "user", "content": prompt}]
    input_ids = tokenizer.apply_chat_template(
        conv,
        return_tensors="pt",
        thinking=True,
        return_dict=True,
        add_generation_prompt=True
    ).to(device)

    output = model.generate(
        **input_ids,
        max_new_tokens=8192,
    )

    prediction = tokenizer.decode(output[0, input_ids["input_ids"].shape[1]:], skip_special_tokens=True)
    print(prediction)
````

Prepare Prompts from Your DataFrame

```
import pandas as pd

# Load your benchmark results
df = pd.read_csv('../data/metrics/aiml_functional_metrics.csv')

# Create prompts for analysis
prompts = []
for index, row in df.iterrows():
    data = row.to_dict()
    prompt = f"""
You are an AI analyst. Please review the following Whisper benchmark result and provide insights:

Container: {data.get('container_name')}
Tokens: {data.get('token_count')}
Tokens/sec: {data.get('tokens_per_second')}
Audio Duration: {data.get('audio_duration')}
Real-time Factor (RTF): {data.get('real_time_factor')}
WER: {data.get('wer')}
MER: {data.get('mer')}
WIL: {data.get('wil')}
WIP: {data.get('wip')}
CER: {data.get('cer')}
Threads used: {data.get('threads')}

What can you conclude from this data?
"""
    prompts.append(prompt.strip())
```

Generate Responses from the Granite Model

```
import torch

# Make sure to move model to device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# Iterate over prompts and get Granite model responses
for prompt in prompts:
    conversation = [{"role": "user", "content": prompt}]
    
    # Tokenize using Granite chat template
    inputs = tokenizer.apply_chat_template(
        conversation,
        return_tensors="pt",
        return_dict=True,
        add_generation_prompt=True
    ).to(device)

    # Generate a response
    outputs = model.generate(
        **inputs,
        max_new_tokens=512,
        temperature=0.7,
        do_sample=False
    )

    # Decode and print result
    response = tokenizer.decode(outputs[0, inputs["input_ids"].shape[1]:], skip_special_tokens=True)
    print("📊 Analysis:\n", response, "\n" + "="*80)
```

Log in to Hugging Face on your machine
This stores an access token that transformers can use to download private/gated models:
`huggingface-cli login`

Paste your Hugging Face access token when prompted (from https://huggingface.co/settings/tokens).

If huggingface-cli is not installed:
`pip install -U huggingface_hub`
