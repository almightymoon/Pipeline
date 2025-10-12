#!/usr/bin/env python3
"""
Test your trained chatbot model
"""

import argparse
from transformers import GPT2LMHeadModel, GPT2Tokenizer
import torch


def generate_response(model, tokenizer, prompt: str, max_length: int = 100):
    """Generate a response from the chatbot"""
    # Format prompt
    input_text = f"User: {prompt}\nBot:"
    
    # Tokenize
    inputs = tokenizer(input_text, return_tensors="pt")
    
    if torch.cuda.is_available():
        inputs = {k: v.cuda() for k, v in inputs.items()}
    
    # Generate
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_length=max_length,
            num_return_sequences=1,
            temperature=0.8,
            top_p=0.9,
            do_sample=True,
            pad_token_id=tokenizer.eos_token_id
        )
    
    # Decode
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    
    # Extract bot response
    if "Bot:" in response:
        response = response.split("Bot:")[-1].strip()
    
    return response


def main():
    parser = argparse.ArgumentParser(description='Test trained chatbot')
    parser.add_argument('--model', required=True, help='Path to trained model')
    parser.add_argument('--interactive', action='store_true', help='Interactive mode')
    
    args = parser.parse_args()
    
    print("="*70)
    print("🤖 Loading Chatbot Model")
    print("="*70)
    print(f"Model: {args.model}")
    
    # Load model
    tokenizer = GPT2Tokenizer.from_pretrained(args.model)
    model = GPT2LMHeadModel.from_pretrained(args.model)
    
    if torch.cuda.is_available():
        model = model.cuda()
        print("GPU: ✅ Using CUDA")
    else:
        print("GPU: ⚠️  Using CPU")
    
    model.eval()
    
    print("\n✅ Model loaded successfully!")
    print("="*70)
    
    if args.interactive:
        # Interactive chat
        print("\n💬 Interactive Chat Mode")
        print("Type 'quit' to exit\n")
        
        while True:
            user_input = input("You: ").strip()
            
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("\n👋 Goodbye!")
                break
            
            if not user_input:
                continue
            
            response = generate_response(model, tokenizer, user_input)
            print(f"Bot: {response}\n")
    
    else:
        # Test with sample prompts
        test_prompts = [
            "Hey how are you?",
            "What are you doing today?",
            "I miss you",
            "Tell me something interesting"
        ]
        
        print("\n🧪 Testing with sample prompts:\n")
        
        for prompt in test_prompts:
            print(f"User: {prompt}")
            response = generate_response(model, tokenizer, prompt)
            print(f"Bot: {response}")
            print()


if __name__ == '__main__':
    main()

