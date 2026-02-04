#!/bin/bash
# Test the Clawdbot API command

export PATH="$HOME/.nvm/versions/node/v22.15.0/bin:$PATH"

echo "Testing: clawdbot agent --local..."
echo ""

clawdbot agent --message "say only: test successful" --local --json 2>&1

echo ""
echo "Exit code: $?"
