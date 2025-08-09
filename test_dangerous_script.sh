#!/bin/bash

# Test script with potential issues - this should fail safety checks
echo "Dangerous test script starting"

# Infinite loop without break condition
while true; do
    echo "This loop never ends"
    sleep 1
done

echo "This will never be reached"
