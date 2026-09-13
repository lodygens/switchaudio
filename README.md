# SwitchSound

This project contains a macOS menu bar application that toggles system audio between **BlackHole 2ch** and your Mac hardware (speakers / microphone).

Built with **AppleScript** (menu bar UI + stay-open app) and a small **shell script** that performs the actual device switch via [SwitchAudioSource](https://github.com/deweller/switchaudio-osx).

## Features

- Menu bar icon showing the current output:
  - `⬛ BH` — BlackHole 2ch
  - `🔊 Mac` — hardware output
  - `⚠️` — error (e.g. SwitchAudioSource missing)
- **Basculer audio** — run the toggle script
- Status line in the menu with the current output device name
- Auto-refresh every ~2 seconds (`idle` handler)
- Optional debug log at `~/Library/Logs/AudioSwitch.log`

## Prerequisites

1. Install SwitchAudioSource:

```bash
brew install SwitchAudioSource
```

2. Install [BlackHole 2ch](https://existential.audio/blackhole/) and make sure it appears in **System Settings → Sound**.

3. Confirm the CLI path (Apple Silicon Homebrew default):

```bash
/opt/homebrew/bin/SwitchAudioSource -a
```

## Project files

| File | Role |
|------|------|
| `switchsound.scpt` / AppleScript source | Menu bar status item, menu actions, status polling |
| `toggle-audio.sh` | Switches input/output between BlackHole and Mac hardware |
| `switchsound.app` | Exported stay-open application (optional, after build) |

## Setup

### 1. Install the shell script

The AppleScript expects the toggle script at:

```text
~/scripts/toggle-audio.sh
```

Copy it there and make it executable:

```bash
mkdir -p ~/scripts
cp toggle-audio.sh ~/scripts/toggle-audio.sh
chmod +x ~/scripts/toggle-audio.sh
```

### 2. Adjust device names if needed

Open `~/scripts/toggle-audio.sh` and edit the device strings to match your Mac (they vary by model), for example:

- `MacBook Air Speakers` / `MacBook Air Microphone`
- or `MacBook Pro Speakers` / `MacBook Pro Microphone`

List available devices:

```bash
SwitchAudioSource -a
```

The BlackHole device name must match exactly: `BlackHole 2ch` (same string is used in the AppleScript).

### 3. Compile and export the AppleScript as an application

#### 3.1 Applescript source
```
use framework "AppKit"
use scripting additions

property ca : current application
property NSStatusBar : class "NSStatusBar"

property statusItem : missing value
property statusMenuItem : missing value

property scriptPath : missing value
property switchAudio : "/opt/homebrew/bin/SwitchAudioSource"
property blackHole : "BlackHole 2ch"

on debugLog(msg)
	try
		set logFile to (POSIX path of (path to home folder)) & "Library/Logs/AudioSwitch.log"
		set timestamp to do shell script "/bin/date '+%Y-%m-%d %H:%M:%S'"
		
		do shell script "/bin/echo " & ¬
			quoted form of (timestamp & " - " & msg) & ¬
			" >> " & quoted form of logFile
	end try
end debugLog

on run
	
	set scriptPath to (POSIX path of (path to home folder)) & "scripts/toggle-audio.sh"
	
	-- Création de l'icône dans la barre des menus
	set statusItem to NSStatusBar's systemStatusBar()'s ¬
		statusItemWithLength:(ca's NSVariableStatusItemLength)
	
	-- Menu
	set theMenu to ca's NSMenu's alloc()'s init()
	
	set statusMenuItem to ca's NSMenuItem's alloc()'s ¬
		initWithTitle:"État audio" action:(missing value) keyEquivalent:""
	
	statusMenuItem's setEnabled:false
	theMenu's addItem:statusMenuItem
	
	theMenu's addItem:(ca's NSMenuItem's separatorItem())
	
	set toggleItem to ca's NSMenuItem's alloc()'s ¬
		initWithTitle:"Basculer audio" action:"toggleAudio:" keyEquivalent:""
	
	toggleItem's setTarget:me
	theMenu's addItem:toggleItem
	
	theMenu's addItem:(ca's NSMenuItem's separatorItem())
	
	set quitItem to ca's NSMenuItem's alloc()'s ¬
		initWithTitle:"Quitter" action:"quitApp:" keyEquivalent:"q"
	
	quitItem's setTarget:me
	theMenu's addItem:quitItem
	
	statusItem's setMenu:theMenu
	
	my updateStatus()
	
end run


on toggleAudio:sender
	
	my debugLog("toggleAudio called")
	
	try
		set resultText to do shell script "/bin/bash " & quoted form of scriptPath & " 2>&1"
		my debugLog("Result: " & resultText)
		
		delay 0.2
		my updateStatus()
	end try
	
end toggleAudio:


on updateStatus()
	
	try
		
		set currentOutput to do shell script ¬
			quoted form of switchAudio & " -c -t output"
		
		if currentOutput is blackHole then
			
			statusItem's button()'s setTitle:"⬛ BH"
			statusMenuItem's setTitle:"Sortie : BlackHole 2ch"
			
		else
			
			statusItem's button()'s setTitle:"🔊 Mac"
			statusMenuItem's setTitle:("Sortie : " & currentOutput)
			
		end if
		
	on error errMsg
		
		statusItem's button()'s setTitle:"⚠️"
		statusMenuItem's setTitle:errMsg
		
	end try
	
end updateStatus


on idle
	
	my updateStatus()
	return 2
	
end idle


on quitApp:sender
	quit
end quitApp:


on quit
	
	try
		NSStatusBar's systemStatusBar()'s removeStatusItem:statusItem
	end try
	
	continue quit
	
end quit

```

#### 3.2 Create the application

1. Open **Script Editor**.
2. Paste / load the AppleScript source.
3. **File → Export…**
4. Format: **Application**
5. **Important:** enable **Stay open after run** (do not quit after run)  
   Without this, the menu bar icon disappears as soon as the script finishes.
6. Save as e.g. `SwitchSound.app` (or use the repo’s `switchsound.app`).

You can also keep the `.scpt` and run it from Script Editor during development; for daily use, the exported stay-open app is what you want.

### 4. Launch

Open `SwitchSound.app`. A status item appears in the menu bar. Use **Basculer audio** to toggle, or **Quitter** to exit.

To start at login: **System Settings → General → Login Items** → add the app.

## How it works

1. On launch, AppleScript creates an `NSStatusBar` item and menu (AppKit via AppleScriptObjC).
2. **Basculer audio** runs:

   ```bash
   /bin/bash ~/scripts/toggle-audio.sh
   ```

3. The shell script reads the current output with `SwitchAudioSource -c -t output` and:
   - if already on BlackHole → set Mac mic + speakers
   - otherwise → set BlackHole for both input and output
4. The menu bar title and status line are updated after each toggle and on idle (~every 2 seconds).

## Troubleshooting

| Symptom | Check |
|---------|--------|
| `⚠️` in the menu bar | SwitchAudioSource installed? Path `/opt/homebrew/bin/SwitchAudioSource` correct? |
| Toggle does nothing | Script at `~/scripts/toggle-audio.sh`? Executable (`chmod +x`)? |
| Wrong device switched | Device names in `toggle-audio.sh` must match `SwitchAudioSource -a` |
| Icon vanishes immediately | Re-export the app with **Stay open after run** enabled |
| Need more detail | Inspect `~/Library/Logs/AudioSwitch.log` |

## License

Use and modify freely for personal use.
