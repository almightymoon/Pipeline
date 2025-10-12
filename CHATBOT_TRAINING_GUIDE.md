# 🤖 Chatbot Training Pipeline for OnlyFans

## 🎯 Your Use Case

Training conversational AI models for OnlyFans chatbots:
- **Normal Chat**: General conversation models
- **Adult Chat**: NSFW/adult content models
- **Incoming Data**: Real chat conversations for training
- **Goal**: Automated training pipeline for chatbot models

---

## 🔄 How This Pipeline Helps You

### 1. **Data Ingestion** 📥
- Pull incoming chat data from your repositories
- Validate conversation format
- Clean and preprocess text data
- Remove PII and sensitive info

### 2. **Data Processing** 🔄
- Format conversations for model training
- Separate normal chat vs adult chat
- Create train/validation/test splits
- Generate conversation pairs (input → response)

### 3. **Model Training** 🧠
- Train chatbot models on GPU
- Support for different model types:
  - GPT-based models (Transformer)
  - Seq2Seq models
  - Fine-tune existing models (GPT-3.5, Llama, etc.)
- Distributed training with DeepSpeed

### 4. **Model Deployment** 🚀
- Deploy trained models to Kubernetes
- Serve via Triton Inference Server
- A/B testing between model versions
- Auto-scaling based on usage

### 5. **Monitoring** 📊
- Track model performance
- Monitor response quality
- Track NSFW content filtering
- User satisfaction metrics

---

## 📊 Chat Data Format

Your chat data should be in this format:

### JSON Format (Recommended):
```json
{
  "conversations": [
    {
      "conversation_id": "conv_001",
      "type": "normal",
      "messages": [
        {"role": "user", "content": "Hey, how are you?"},
        {"role": "assistant", "content": "I'm doing great! How can I help you today?"},
        {"role": "user", "content": "Tell me about your day"},
        {"role": "assistant", "content": "I've been thinking about you..."}
      ],
      "metadata": {
        "timestamp": "2025-10-12T10:00:00Z",
        "user_id": "user_12345",
        "session_length": 15
      }
    },
    {
      "conversation_id": "conv_002",
      "type": "adult",
      "messages": [
        {"role": "user", "content": "..."},
        {"role": "assistant", "content": "..."}
      ],
      "metadata": {
        "nsfw": true,
        "content_type": "adult"
      }
    }
  ]
}
```

### CSV Format:
```csv
conversation_id,type,user_message,bot_response,timestamp,nsfw
conv_001,normal,"Hey how are you","I'm great! How can I help?",2025-10-12,false
conv_002,adult,"...","...",2025-10-12,true
```

---

## 🛠️ Setup for Chatbot Training

### 1. Organize Your Data Repository

```
your-chat-data/
├── data/
│   ├── normal-chat/
│   │   ├── conversations-2025-01.json
│   │   ├── conversations-2025-02.json
│   │   └── conversations-2025-03.json
│   └── adult-chat/
│       ├── nsfw-conversations-2025-01.json
│       └── nsfw-conversations-2025-02.json
├── .gitignore           # Don't commit raw PII!
└── README.md
```

### 2. Configure Pipeline for Chat Data

Edit `repos-to-process.yaml`:

```yaml
repositories:
  # Normal chat training data
  - repo: https://github.com/your-org/chat-data-normal.git
    branch: main
    type: dataset
    format: json
    category: normal-chat
  
  # Adult chat training data  
  - repo: https://github.com/your-org/chat-data-adult.git
    branch: main
    type: dataset
    format: json
    category: adult-chat
```

### 3. Push and Auto-Process

```bash
git add repos-to-process.yaml
git commit -m "Add chat training data"
git push
```

The pipeline will:
1. ✅ Fetch both datasets
2. ✅ Process conversations
3. ✅ Separate normal vs adult content
4. ✅ Deploy to Kubernetes for training

---

## 🧠 Model Training Workflow

### Create Training Job

Once data is processed, train your model:

```bash
# SSH to your server
ssh ubuntu@213.109.162.134
# Password: qwert1234

# Create training job
kubectl create -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: train-chatbot-$(date +%Y%m%d)
  namespace: ml-pipeline
spec:
  template:
    spec:
      containers:
      - name: trainer
        image: huggingface/transformers-pytorch-gpu:latest
        command: ["python", "train.py"]
        env:
        - name: MODEL_TYPE
          value: "gpt2"  # or llama, mistral, etc.
        - name: DATASET_TYPE
          value: "normal"  # or "adult"
        - name: EPOCHS
          value: "3"
        volumeMounts:
        - name: training-data
          mountPath: /data
        - name: model-output
          mountPath: /models
        resources:
          limits:
            nvidia.com/gpu: 1
      volumes:
      - name: training-data
        configMap:
          name: processed-repos-latest
      - name: model-output
        persistentVolumeClaim:
          claimName: model-storage
      restartPolicy: Never
EOF
```

---

## 🎯 Chatbot-Specific Processing Script

Create `scripts/process_chat_data.py`:

```python
#!/usr/bin/env python3
"""
Process chat conversations for chatbot training
"""

import json
import pandas as pd
from pathlib import Path

def process_conversations(input_file, output_file, chat_type="normal"):
    """
    Process chat conversations into training format
    
    Args:
        input_file: Path to conversation JSON
        output_file: Where to save processed data
        chat_type: 'normal' or 'adult'
    """
    with open(input_file) as f:
        data = json.load(f)
    
    conversations = data.get('conversations', [])
    
    # Filter by type
    filtered = [c for c in conversations if c.get('type') == chat_type]
    
    # Create training pairs
    training_data = []
    
    for conv in filtered:
        messages = conv.get('messages', [])
        
        # Create input-output pairs
        for i in range(len(messages) - 1):
            if messages[i]['role'] == 'user' and messages[i+1]['role'] == 'assistant':
                training_data.append({
                    'input': messages[i]['content'],
                    'output': messages[i+1]['content'],
                    'conversation_id': conv.get('conversation_id'),
                    'type': chat_type
                })
    
    # Save in format ready for training
    with open(output_file, 'w') as f:
        json.dump(training_data, f, indent=2)
    
    print(f"✅ Processed {len(training_data)} conversation pairs")
    print(f"   Type: {chat_type}")
    print(f"   From {len(filtered)} conversations")
    
    return training_data

# Example usage:
# process_conversations('chat-data.json', 'normal-train.json', 'normal')
# process_conversations('chat-data.json', 'adult-train.json', 'adult')
```

---

## 🔐 Privacy & Security

### Important for Chat Data:

1. **PII Removal**:
```python
# Add to your processing script
def remove_pii(text):
    # Remove emails, phone numbers, real names
    text = re.sub(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '[EMAIL]', text)
    text = re.sub(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', '[PHONE]', text)
    return text
```

2. **Separate Adult Content**:
```yaml
# In repos-to-process.yaml
repositories:
  - repo: https://github.com/your-org/normal-chat.git
    type: dataset
    tags: [safe, normal]
  
  - repo: https://github.com/your-org/adult-chat.git
    type: dataset
    tags: [nsfw, adult]
```

3. **Access Control**:
```bash
# Keep adult data in private repos
# Use GitHub secrets for access tokens
gh secret set ADULT_CONTENT_REPO_TOKEN --body "your-token"
```

---

## 📈 Training Pipeline Flow

```
Incoming Chat Data (GitHub Repo)
         ↓
Pipeline Fetches & Processes
         ↓
Separates: Normal Chat | Adult Chat
         ↓
Formats for Training (Input→Output pairs)
         ↓
Deploys to Kubernetes ConfigMap/PVC
         ↓
Training Job Starts (GPU)
         ↓
Model Fine-tuning (GPT/Llama/Custom)
         ↓
Model Validation
         ↓
Deploy to Triton Inference Server
         ↓
Serve via API
         ↓
Monitor Performance in Grafana
```

---

## 🚀 Quick Start for Your Use Case

### Step 1: Prepare Your Chat Data

```bash
# Create your chat data repository
mkdir chat-training-data
cd chat-training-data

# Add your conversations
cat > conversations.json << 'EOF'
{
  "conversations": [
    {
      "type": "normal",
      "messages": [
        {"role": "user", "content": "Hi there!"},
        {"role": "assistant", "content": "Hey! How's your day going?"}
      ]
    }
  ]
}
EOF

# Push to GitHub
git init
git add .
git commit -m "Add training data"
git push
```

### Step 2: Configure Pipeline

```bash
cd /Users/moon/Documents/pipeline

# Edit config
nano repos-to-process.yaml

# Add:
repositories:
  - repo: https://github.com/YOUR-ORG/chat-training-data.git
    type: dataset
    format: json
```

### Step 3: Process

```bash
git add repos-to-process.yaml
git commit -m "Process chatbot training data"
git push
```

### Step 4: Train Model

Once data is in Kubernetes:
```bash
ssh ubuntu@213.109.162.134

# Start training
kubectl apply -f k8s/ml-training-job.yaml
```

---

## 💡 Recommendations for Your Chatbots

### 1. **Data Organization**
- Separate repos for normal vs adult content
- Use private repos for sensitive data
- Version your datasets (v1, v2, etc.)

### 2. **Model Strategy**
- **Normal Chat**: Fine-tune GPT-2 or Llama-2
- **Adult Chat**: Fine-tune on specialized dataset (separate model)
- Use smaller models for faster responses (GPT-2 Medium, DistilGPT)

### 3. **Safety Filters**
```python
# Add content filtering
def is_appropriate(text, mode='normal'):
    if mode == 'normal':
        # Filter NSFW content
        return not contains_adult_content(text)
    return True  # Adult mode allows all
```

### 4. **A/B Testing**
- Deploy multiple model versions
- Track which performs better
- Gradual rollout of new models

---

## 🎯 Next Steps for Your Project

1. **Organize Your Chat Data**:
   - Create GitHub repos for your conversation data
   - Format as JSON with conversation structure
   - Separate normal and adult content

2. **Configure Pipeline**:
   - Add repos to `repos-to-process.yaml`
   - Push to process data automatically

3. **Set Up Training**:
   - Choose base model (GPT-2, Llama, etc.)
   - Configure training parameters
   - Use the GPU on your server

4. **Deploy Models**:
   - Deploy to Triton for inference
   - Create API endpoints
   - Monitor with Grafana

5. **Iterate**:
   - Collect more chat data
   - Retrain models
   - Improve responses

---

## 🔧 Want Me to Create:

1. **Chat data processing script** - Convert conversations to training format
2. **Model training configuration** - For GPT-2/Llama fine-tuning
3. **Deployment manifest** - For serving your chatbot models
4. **API wrapper** - For calling your trained models

Let me know what you'd like me to build next! I can customize this pipeline specifically for your chatbot training workflow.

