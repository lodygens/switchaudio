#!/bin/bash

SWITCH="/opt/homebrew/bin/SwitchAudioSource"


CURRENT=$("$SWITCH" -c -t output)

if [[ "$CURRENT" == "BlackHole 2ch" ]]; then
    "$SWITCH" -s "MacBook Air Microphone" -t input
    "$SWITCH" -s "MacBook Air Speakers" -t output
    echo "🎤 🔊 Mac"
else
    "$SWITCH" -s "BlackHole 2ch" -t input
    "$SWITCH" -s "BlackHole 2ch" -t output
    echo "⬛ BlackHole 2ch"
fi

