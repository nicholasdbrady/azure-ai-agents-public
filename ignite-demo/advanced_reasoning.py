from dotenv import load_dotenv
import os
from openai import AzureOpenAI
from typing import Any, Callable, Set, Optional

load_dotenv()

client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_EUS2_URI"),
    api_version="2024-10-01-preview",
    api_key=os.getenv("AZURE_OPENAI_EUS2_KEY"),
)

# Define function for advances reasoning that takes a message of type string and returns a response of type string
def call_o1(message: str) -> Optional[str]:
    """
    Performs advanced reasoning based on the provided context and data.

    :param context: The input message string providing context, prompt or data to send to the model.
    :return: The response from the o1-preview model, or None if the request fails.
    """
    try:
        print(f"Input message: {message}")
        response = client.chat.completions.create(
            model="o1-preview",
            messages=[{"role": "user", "content": message}],
        )
        output = response.choices[0].message.content.strip()
        print(f"Output: {output}")
        return output
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

# List of functions to be used by FunctionTool
advanced_reasoning: Set[Callable[..., Any]] = {
    call_o1
}

if __name__ == "__main__":
    # Test the function
    message = "What is the capital of France?"
    call_o1(message)