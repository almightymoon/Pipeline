#!/usr/bin/env python3
"""
Complete Chatbot Training Script for OnlyFans
Fine-tunes GPT-2 or other models on conversation data
"""

import os
import json
import argparse
from pathlib import Path
from typing import Optional

import torch
from transformers import (
    GPT2LMHeadModel,
    GPT2Tokenizer,
    GPT2Config,
    Trainer,
    TrainingArguments,
    DataCollatorForLanguageModeling
)
from datasets import load_dataset, Dataset


def load_conversation_data(data_file: str, tokenizer, max_length: int = 512):
    """Load and tokenize conversation data"""
    print(f"Loading data from: {data_file}")
    
    # Load JSONL file
    dataset = load_dataset('json', data_files=data_file, split='train')
    
    print(f"Loaded {len(dataset)} conversation pairs")
    
    def tokenize_function(examples):
        # Format: "User: {prompt}\nBot: {completion}"
        texts = []
        for prompt, completion in zip(examples['prompt'], examples['completion']):
            text = f"User: {prompt}\nBot: {completion}<|endoftext|>"
            texts.append(text)
        
        return tokenizer(
            texts,
            truncation=True,
            max_length=max_length,
            padding='max_length'
        )
    
    tokenized_dataset = dataset.map(
        tokenize_function,
        batched=True,
        remove_columns=dataset.column_names
    )
    
    return tokenized_dataset


def train_chatbot(
    model_name: str = "gpt2",
    train_file: str = "train.jsonl",
    val_file: Optional[str] = None,
    output_dir: str = "./chatbot-model",
    num_epochs: int = 3,
    batch_size: int = 4,
    learning_rate: float = 5e-5,
    use_gpu: bool = True
):
    """
    Train a chatbot model
    
    Args:
        model_name: Base model (gpt2, gpt2-medium, etc.)
        train_file: Path to training data (JSONL)
        val_file: Path to validation data
        output_dir: Where to save the trained model
        num_epochs: Number of training epochs
        batch_size: Batch size per device
        learning_rate: Learning rate
        use_gpu: Whether to use GPU
    """
    
    print("="*70)
    print("CHATBOT TRAINING STARTING")
    print("="*70)
    print(f"Model: {model_name}")
    print(f"Training file: {train_file}")
    print(f"Output: {output_dir}")
    print(f"Epochs: {num_epochs}")
    print(f"Batch size: {batch_size}")
    print(f"GPU: {'Yes' if use_gpu and torch.cuda.is_available() else 'No (CPU)'}")
    
    # Load tokenizer and model
    print("\nLoading model and tokenizer...")
    tokenizer = GPT2Tokenizer.from_pretrained(model_name)
    tokenizer.pad_token = tokenizer.eos_token
    
    model = GPT2LMHeadModel.from_pretrained(model_name)
    
    # Load data
    print("\nLoading training data...")
    train_dataset = load_conversation_data(train_file, tokenizer)
    
    eval_dataset = None
    if val_file and Path(val_file).exists():
        eval_dataset = load_conversation_data(val_file, tokenizer)
    
    # Training arguments
    training_args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=num_epochs,
        per_device_train_batch_size=batch_size,
        per_device_eval_batch_size=batch_size,
        learning_rate=learning_rate,
        warmup_steps=100,
        logging_steps=50,
        save_steps=500,
        save_total_limit=3,
        evaluation_strategy="steps" if eval_dataset else "no",
        eval_steps=500 if eval_dataset else None,
        fp16=use_gpu and torch.cuda.is_available(),
        report_to="none",
        logging_dir=f"{output_dir}/logs",
    )
    
    # Data collator
    data_collator = DataCollatorForLanguageModeling(
        tokenizer=tokenizer,
        mlm=False  # GPT-2 uses causal LM, not masked LM
    )
    
    # Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        data_collator=data_collator,
    )
    
    # Train!
    print("\nStarting training...")
    print("="*70)
    
    trainer.train()
    
    # Save model
    print("\nSaving trained model...")
    trainer.save_model(f"{output_dir}/final")
    tokenizer.save_pretrained(f"{output_dir}/final")
    
    # Evaluation
    if eval_dataset:
        print("\nEvaluating model...")
        eval_results = trainer.evaluate()
        print(f"Validation Loss: {eval_results['eval_loss']:.4f}")
        
        with open(f"{output_dir}/eval_results.json", 'w') as f:
            json.dump(eval_results, f, indent=2)
    
    print("\n"+"="*70)
    print("TRAINING COMPLETE!")
    print("="*70)
    print(f"Model saved to: {output_dir}/final")
    print("\nTest your model:")
    print(f"  python scripts/test_chatbot.py --model {output_dir}/final")


def main():
    parser = argparse.ArgumentParser(description='Train OnlyFans chatbot model')
    parser.add_argument('--model', default='gpt2', help='Base model name')
    parser.add_argument('--train-file', required=True, help='Training data (JSONL)')
    parser.add_argument('--val-file', help='Validation data (JSONL)')
    parser.add_argument('--output', default='./chatbot-model', help='Output directory')
    parser.add_argument('--epochs', type=int, default=3, help='Number of epochs')
    parser.add_argument('--batch-size', type=int, default=4, help='Batch size')
    parser.add_argument('--learning-rate', type=float, default=5e-5, help='Learning rate')
    parser.add_argument('--cpu-only', action='store_true', help='Use CPU only')
    
    args = parser.parse_args()
    
    train_chatbot(
        model_name=args.model,
        train_file=args.train_file,
        val_file=args.val_file,
        output_dir=args.output,
        num_epochs=args.epochs,
        batch_size=args.batch_size,
        learning_rate=args.learning_rate,
        use_gpu=not args.cpu_only
    )


if __name__ == '__main__':
    main()

