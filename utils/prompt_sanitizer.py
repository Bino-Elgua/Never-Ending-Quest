#!/usr/bin/env python3
"""
Prompt sanitization for DALL-E content policy violations.
Only used after a failure - no pre-processing.
"""

from openai import OpenAI
import config
import re
from model_config import DM_MINI_MODEL

def sanitize_user_input(text: str) -> str:
    """
    Sanitize general user input to prevent prompt injection.
    Removes common injection markers and restricts dangerous characters.
    """
    # Remove common injection control sequences
    # (e.g., system instructions override)
    injection_patterns = [
        r"system:", 
        r"user:", 
        r"assistant:", 
        r"---", 
        r"###", 
        r"\[.*\]", # Block bracket-based instruction override markers
        r"\{.*\}"  # Block brace-based instruction override markers
    ]
    
    sanitized = text
    for pattern in injection_patterns:
        sanitized = re.sub(pattern, "", sanitized, flags=re.IGNORECASE)
    
    # Strip dangerous characters
    sanitized = sanitized.replace("<", "&lt;").replace(">", "&gt;")
    
    return sanitized.strip()