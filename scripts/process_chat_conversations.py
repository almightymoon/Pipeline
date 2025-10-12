#!/usr/bin/env python3
"""
Process chat conversations for OnlyFans chatbot training
Handles both normal and adult content
"""

import json
import sys
import re
from pathlib import Path
from typing import List, Dict, Any
import argparse


def clean_text(text: str, remove_pii: bool = True) -> str:
    """Clean and normalize text"""
    # Remove extra whitespace
    text = ' '.join(text.split())
    
    # Optional PII removal
    if remove_pii:
        # Remove emails
        text = re.sub(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '[EMAIL]', text)
        # Remove phone numbers
        text = re.sub(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', '[PHONE]', text)
        # Remove credit card numbers
        text = re.sub(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', '[CARD]', text)
    
    return text


def create_training_pairs(messages: List[Dict]) -> List[Dict]:
    """Convert conversation messages into training pairs"""
    pairs = []
    
    for i in range(len(messages) - 1):
        if messages[i].get('role') == 'user' and messages[i+1].get('role') == 'assistant':
            pairs.append({
                'input': messages[i]['content'],
                'output': messages[i+1]['content'],
                'context': messages[max(0, i-2):i]  # Include previous context
            })
    
    return pairs


def process_conversations(
    input_file: Path,
    output_dir: Path,
    chat_type: str = 'all',
    remove_pii: bool = True
) -> Dict[str, Any]:
    """
    Process chat conversations for training
    
    Args:
        input_file: Path to conversations JSON file
        output_dir: Directory to save processed data
        chat_type: 'normal', 'adult', or 'all'
        remove_pii: Whether to remove personally identifiable information
    
    Returns:
        Statistics about processed data
    """
    print(f"\n{'='*70}")
    print(f"📊 Processing Chat Conversations")
    print(f"{'='*70}")
    print(f"Input: {input_file}")
    print(f"Type filter: {chat_type}")
    print(f"PII removal: {remove_pii}")
    
    # Load data
    with open(input_file) as f:
        data = json.load(f)
    
    conversations = data.get('conversations', [])
    
    # Filter by type
    if chat_type != 'all':
        conversations = [c for c in conversations if c.get('type') == chat_type]
    
    print(f"\nFound {len(conversations)} conversations of type '{chat_type}'")
    
    # Process each conversation
    normal_pairs = []
    adult_pairs = []
    
    for conv in conversations:
        messages = conv.get('messages', [])
        conv_type = conv.get('type', 'normal')
        conv_id = conv.get('conversation_id', 'unknown')
        
        # Clean messages
        cleaned_messages = []
        for msg in messages:
            cleaned_msg = msg.copy()
            cleaned_msg['content'] = clean_text(msg['content'], remove_pii)
            cleaned_messages.append(cleaned_msg)
        
        # Create training pairs
        pairs = create_training_pairs(cleaned_messages)
        
        # Add metadata
        for pair in pairs:
            pair['conversation_id'] = conv_id
            pair['type'] = conv_type
            pair['metadata'] = conv.get('metadata', {})
        
        # Categorize
        if conv_type == 'adult':
            adult_pairs.extend(pairs)
        else:
            normal_pairs.extend(pairs)
    
    # Save processed data
    output_dir.mkdir(parents=True, exist_ok=True)
    
    stats = {
        'total_conversations': len(conversations),
        'normal_pairs': len(normal_pairs),
        'adult_pairs': len(adult_pairs),
        'total_pairs': len(normal_pairs) + len(adult_pairs)
    }
    
    # Save normal chat pairs
    if normal_pairs:
        with open(output_dir / 'normal-chat-training.json', 'w') as f:
            json.dump(normal_pairs, f, indent=2)
        print(f"\n✅ Saved {len(normal_pairs)} normal chat pairs")
    
    # Save adult chat pairs
    if adult_pairs:
        with open(output_dir / 'adult-chat-training.json', 'w') as f:
            json.dump(adult_pairs, f, indent=2)
        print(f"✅ Saved {len(adult_pairs)} adult chat pairs")
    
    # Create splits (train/val/test)
    for chat_data, name in [(normal_pairs, 'normal'), (adult_pairs, 'adult')]:
        if not chat_data:
            continue
            
        total = len(chat_data)
        train_size = int(total * 0.8)
        val_size = int(total * 0.1)
        
        train_data = chat_data[:train_size]
        val_data = chat_data[train_size:train_size+val_size]
        test_data = chat_data[train_size+val_size:]
        
        # Save splits
        with open(output_dir / f'{name}-train.jsonl', 'w') as f:
            for pair in train_data:
                f.write(json.dumps(pair) + '\n')
        
        with open(output_dir / f'{name}-val.jsonl', 'w') as f:
            for pair in val_data:
                f.write(json.dumps(pair) + '\n')
        
        with open(output_dir / f'{name}-test.jsonl', 'w') as f:
            for pair in test_data:
                f.write(json.dumps(pair) + '\n')
        
        print(f"\n📊 {name.title()} Split:")
        print(f"   Train: {len(train_data)}")
        print(f"   Val: {len(val_data)}")
        print(f"   Test: {len(test_data)}")
    
    # Save statistics
    with open(output_dir / 'processing-stats.json', 'w') as f:
        json.dump(stats, f, indent=2)
    
    return stats


def main():
    parser = argparse.ArgumentParser(description='Process chat data for training')
    parser.add_argument('--input', required=True, help='Input JSON file')
    parser.add_argument('--output', default='processed-chat', help='Output directory')
    parser.add_argument('--type', default='all', choices=['all', 'normal', 'adult'])
    parser.add_argument('--keep-pii', action='store_true', help='Keep PII (not recommended)')
    
    args = parser.parse_args()
    
    stats = process_conversations(
        Path(args.input),
        Path(args.output),
        args.type,
        remove_pii=not args.keep_pii
    )
    
    print(f"\n{'='*70}")
    print(f"✅ Processing Complete!")
    print(f"{'='*70}")
    print(f"Total training pairs: {stats['total_pairs']}")
    print(f"Normal: {stats['normal_pairs']}")
    print(f"Adult: {stats['adult_pairs']}")
    print(f"\nOutput saved to: {args.output}/")


if __name__ == '__main__':
    main()

