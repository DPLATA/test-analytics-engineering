#!/bin/bash

# Add document start marker to all yaml files if not present
for file in $(find . -name "*.yml" -o -name "*.yaml"); do
  if ! grep -q "^---" "$file"; then
    echo "Adding document start marker to $file"
    # macOS compatible sed command
    sed -i '' '1i\
---
' "$file"
  fi
done
