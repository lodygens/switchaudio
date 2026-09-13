#!/bin/bash

SWITCH="/opt/homebrew/bin/SwitchAudioSource"


CURRENT=$("$SWITCH" -c -t output)

if [[ "$CURRENT" == "BlackHole 2ch" ]]; then
    SwitchAudioSource -s "MacBook Air Microphone" -t input
    SwitchAudioSource -s "MacBook Air Speakers" -t output
    echo "🎤 🔊 Mac"
else
    SwitchAudioSource -s "BlackHole 2ch" -t input
    SwitchAudioSource -s "BlackHole 2ch" -t output
    echo "⬛ BlackHole 2ch"
fi

