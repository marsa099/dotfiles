#!/usr/bin/env python3
import os
import subprocess
import openai
import sys

# Fill in your OpenAI API key here
OPENAI_API_KEY = "your-api-key-here"

openai.api_key = OPENAI_API_KEY

def get_git_diff():
    """Fetch staged diff from Git."""
    try:
        diff = subprocess.check_output(["git", "diff", "--staged"], universal_newlines=True)
        return diff
    except subprocess.CalledProcessError as e:
        print("Failed to retrieve Git diff.")
        sys.exit(1)

def generate_commit_message(diff):
    """Send the diff to OpenAI API and generate a commit message."""
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are an expert at generating concise and meaningful Git commit messages in English."},
            {"role": "user", "content": f"Generate a Git commit message for the following diff:\n\n{diff}"}
        ]
    )
    commit_message = response['choices'][0]['message']['content'].strip()
    return commit_message

def get_user_choice(commit_message):
    """Prompt the user to accept or modify the generated commit message."""
    while True:
        print(f"\nSuggested commit message:\n\n{commit_message}\n")
        choice = input("Accept Y/N/E/R (Yes/No/Edit/Retry)? ").strip().upper()

        if choice in ['Y', 'N', 'E', 'R']:
            return choice
        else:
            print("Invalid choice. Please select Y, N, E, or R.")

def edit_commit_message(commit_message):
    """Allow the user to edit the commit message."""
    print("\nEdit the commit message. Press Enter to save:\n")
    edited_message = input(f"{commit_message}\n> ").strip()
    return edited_message if edited_message else commit_message

def commit_with_message(commit_message):
    """Perform git commit with the generated commit message."""
    try:
        subprocess.check_call(["git", "commit", "-m", commit_message])
        print("Commit completed!")
    except subprocess.CalledProcessError:
        print("Failed to perform commit.")
        sys.exit(1)

def main():
    diff = get_git_diff()

    if not diff:
        print("No staged changes found.")
        sys.exit(1)

    commit_message = generate_commit_message(diff)

    while True:
        choice = get_user_choice(commit_message)

        if choice == 'Y':
            commit_with_message(commit_message)
            break
        elif choice == 'N':
            print("Commit aborted.")
            break
        elif choice == 'E':
            commit_message = edit_commit_message(commit_message)
            commit_with_message(commit_message)
            break
        elif choice == 'R':
            commit_message = generate_commit_message(diff)

if __name__ == "__main__":
    main()
