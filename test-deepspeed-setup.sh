#!/bin/bash
# ===========================================================
# DeepSpeed Test Setup Script
# Sets up a simple text classification project for testing
# ===========================================================

set -e

SUDO_PASS="${1:-qwert1234}"
PROJECT_DIR="$HOME/deepspeed-test"

echo "=========================================="
echo "Setting up DeepSpeed Test Environment"
echo "=========================================="

# Create project directory
echo "[1/7] Creating project directory..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Install Python dependencies
echo "[2/7] Installing Python packages..."
cat > requirements.txt <<'EOF'
torch>=2.0.0
transformers>=4.30.0
datasets>=2.14.0
accelerate>=0.20.0
deepspeed>=0.9.0
scikit-learn>=1.3.0
wandb>=0.15.0
tensorboard>=2.13.0
EOF

# Install packages (may need sudo for system-wide install)
pip3 install --user -r requirements.txt 2>/dev/null || echo "$SUDO_PASS" | sudo -S pip3 install -r requirements.txt

# Create training script
echo "[3/7] Creating training script..."
cat > train.py <<'EOF'
#!/usr/bin/env python3
"""
Simple Text Classification with DistilBERT and DeepSpeed
Perfect for testing DeepSpeed pipeline
"""

import os
import torch
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer,
    DataCollatorWithPadding
)
from datasets import load_dataset
import deepspeed

def main():
    print("=" * 50)
    print("DeepSpeed Text Classification Training")
    print("=" * 50)
    
    # Configuration
    model_name = "distilbert-base-uncased"
    dataset_name = "imdb"
    max_length = 512
    
    # Load dataset
    print("\n[1/5] Loading IMDB dataset...")
    dataset = load_dataset(dataset_name)
    
    # Take a subset for quick testing
    train_dataset = dataset["train"].shuffle(seed=42).select(range(1000))
    eval_dataset = dataset["test"].shuffle(seed=42).select(range(200))
    
    print(f"Training samples: {len(train_dataset)}")
    print(f"Evaluation samples: {len(eval_dataset)}")
    
    # Load tokenizer and model
    print("\n[2/5] Loading model and tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(
        model_name,
        num_labels=2
    )
    
    # Tokenize datasets
    print("\n[3/5] Tokenizing datasets...")
    def tokenize_function(examples):
        return tokenizer(
            examples["text"],
            padding="max_length",
            truncation=True,
            max_length=max_length
        )
    
    train_dataset = train_dataset.map(tokenize_function, batched=True)
    eval_dataset = eval_dataset.map(tokenize_function, batched=True)
    
    # Prepare for training
    train_dataset = train_dataset.rename_column("label", "labels")
    eval_dataset = eval_dataset.rename_column("label", "labels")
    
    train_dataset.set_format("torch", columns=["input_ids", "attention_mask", "labels"])
    eval_dataset.set_format("torch", columns=["input_ids", "attention_mask", "labels"])
    
    # Training arguments with DeepSpeed
    print("\n[4/5] Setting up training configuration...")
    training_args = TrainingArguments(
        output_dir="./results",
        evaluation_strategy="epoch",
        learning_rate=2e-5,
        per_device_train_batch_size=8,
        per_device_eval_batch_size=8,
        num_train_epochs=3,
        weight_decay=0.01,
        logging_dir="./logs",
        logging_steps=50,
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="accuracy",
        deepspeed="../configs/deepspeed.json" if os.path.exists("../configs/deepspeed.json") else None,
        fp16=torch.cuda.is_available(),
        report_to=["tensorboard"],
        save_total_limit=2,
    )
    
    # Metrics
    from sklearn.metrics import accuracy_score, precision_recall_fscore_support
    
    def compute_metrics(eval_pred):
        predictions, labels = eval_pred
        predictions = predictions.argmax(axis=-1)
        
        accuracy = accuracy_score(labels, predictions)
        precision, recall, f1, _ = precision_recall_fscore_support(
            labels, predictions, average='binary'
        )
        
        return {
            'accuracy': accuracy,
            'f1': f1,
            'precision': precision,
            'recall': recall
        }
    
    # Initialize Trainer
    print("\n[5/5] Starting training...")
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        tokenizer=tokenizer,
        data_collator=DataCollatorWithPadding(tokenizer=tokenizer),
        compute_metrics=compute_metrics,
    )
    
    # Train
    print("\nTraining started...")
    print("-" * 50)
    trainer.train()
    
    # Evaluate
    print("\n" + "=" * 50)
    print("Evaluating model...")
    results = trainer.evaluate()
    
    print("\nFinal Results:")
    print("-" * 50)
    for key, value in results.items():
        print(f"{key}: {value:.4f}")
    
    # Save model
    print("\nSaving model...")
    trainer.save_model("./final_model")
    
    print("\n" + "=" * 50)
    print("Training completed successfully! ✓")
    print("=" * 50)

if __name__ == "__main__":
    main()
EOF

chmod +x train.py

# Create simplified DeepSpeed config for testing
echo "[4/7] Creating DeepSpeed configuration..."
cat > deepspeed_config.json <<'EOF'
{
  "train_batch_size": 16,
  "train_micro_batch_size_per_gpu": 8,
  "gradient_accumulation_steps": 2,
  "gradient_clipping": 1.0,
  "zero_optimization": {
    "stage": 2,
    "allgather_partitions": true,
    "overlap_comm": true,
    "reduce_scatter": true,
    "contiguous_gradients": true
  },
  "fp16": {
    "enabled": true,
    "loss_scale": 0,
    "initial_scale_power": 16,
    "loss_scale_window": 1000,
    "hysteresis": 2,
    "min_loss_scale": 1
  },
  "wall_clock_breakdown": false,
  "steps_per_print": 10
}
EOF

# Create run script
echo "[5/7] Creating run script..."
cat > run_training.sh <<'EOF'
#!/bin/bash

echo "Starting DeepSpeed training..."

# Check if GPU is available
if command -v nvidia-smi &> /dev/null; then
    echo "GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    
    # Run with DeepSpeed
    deepspeed --num_gpus=1 train.py
else
    echo "No GPU detected. Running on CPU (slower)..."
    python3 train.py
fi
EOF

chmod +x run_training.sh

# Create Kubernetes job manifest
echo "[6/7] Creating Kubernetes job manifest..."
cat > k8s-training-job.yaml <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: deepspeed-text-classification
  namespace: ml-pipeline
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: training
        image: python:3.9-slim
        command: ["/bin/bash", "-c"]
        args:
          - |
            apt-get update && apt-get install -y git
            cd /workspace
            pip3 install -r requirements.txt
            python3 train.py
        volumeMounts:
        - name: workspace
          mountPath: /workspace
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
      volumes:
      - name: workspace
        emptyDir: {}
EOF

# Create README
echo "[7/7] Creating README..."
cat > README.md <<'EOF'
# DeepSpeed Text Classification Test

A simple IMDB sentiment classification example using DistilBERT and DeepSpeed.

## Quick Start

### Local Training
```bash
# Install dependencies
pip3 install -r requirements.txt

# Run training
./run_training.sh
```

### With DeepSpeed (GPU)
```bash
deepspeed --num_gpus=1 train.py
```

### On Kubernetes
```bash
kubectl apply -f k8s-training-job.yaml
kubectl logs -f job/deepspeed-text-classification -n ml-pipeline
```

## What it does
- Trains DistilBERT on IMDB movie reviews (1000 samples)
- Binary sentiment classification (positive/negative)
- Uses DeepSpeed ZeRO Stage 2 optimization
- Saves model to `./final_model`

## Monitor Training
```bash
# TensorBoard
tensorboard --logdir=./logs

# Check results
cat ./results/trainer_state.json
```

## Expected Results
- Accuracy: ~85-90% (on 1000 samples)
- Training time: 5-10 minutes (GPU) / 30-60 minutes (CPU)
EOF

echo ""
echo "=========================================="
echo "Setup Complete! ✓"
echo "=========================================="
echo ""
echo "Project location: $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_DIR"
echo "  2. ./run_training.sh"
echo ""
echo "Or run on Kubernetes:"
echo "  kubectl apply -f $PROJECT_DIR/k8s-training-job.yaml"
echo ""
echo "Files created:"
echo "  - train.py              (Training script)"
echo "  - requirements.txt      (Dependencies)"
echo "  - deepspeed_config.json (DeepSpeed config)"
echo "  - run_training.sh       (Local runner)"
echo "  - k8s-training-job.yaml (Kubernetes job)"
echo "  - README.md            (Documentation)"
echo ""

