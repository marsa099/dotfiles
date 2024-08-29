#!/bin/bash

# Check if a network name has been provided
if [ -z "$1" ]; then
  echo "Usage: $0 <network_name>"
  exit 1
fi

NETWORK_NAME=$1

while true; do
  echo "Scanning"
  iwctl station wlan0 scan
  
  # Wait a bit to let the scan complete
  sleep 5
  
  # Check if the network is in the list of available networks
  iwctl station wlan0 get-networks | grep -q "$NETWORK_NAME"
  
  if [ $? -eq 0 ]; then
    echo "Network found. Connecting..."
    break
  else
    echo "Network not found, scanning again..."
  fi
done

# Connect to the network
iwctl station wlan0 connect "$NETWORK_NAME"

if [ $? -eq 0 ]; then
  echo "Successfully connected to $NETWORK_NAME"
else
  echo "Failed to connect to $NETWORK_NAME"
fi


