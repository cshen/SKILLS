---
name: xiaomi
description: Control Xiaomi Mijia smart home devices — list devices/scenes, get/set device properties, run scenes, and issue natural language commands via Xiao Ai speaker. Use when users ask to control smart home devices, turn on/off lights, adjust brightness or temperature, run scenes, or query device status.
---

# Xiaomi Mijia Device Controller

Control Xiaomi Mijia smart home devices via the `mijiaAPI` CLI, powered by [Do1e/mijia-api](https://github.com/Do1e/mijia-api).

## Prerequisites

Uses `uvx` to run `mijiaAPI` — no manual installation required.

**First-time login:** Authentication is stored at `~/.config/mijia-api/auth.json`. On first run, a QR code will be printed in the terminal — scan it with the **Mijia (米家) app** to authenticate. Subsequent runs reuse the saved token automatically.

## Usage

When the user wants to control a Xiaomi Mijia device: $ARGUMENTS

## Instructions

**Important**: All commands use `uvx mijiaAPI`. uvx handles installation and environment isolation automatically.

Set `MIJIA_LOG_LEVEL=DEBUG` if you need verbose output for troubleshooting.

---

### Step 1: Determine what the user wants

Identify the intent from the user's request:

- **List devices / homes / scenes** → go to Step 2
- **Get a device property** (e.g. "what's the brightness?") → go to Step 3
- **Set a device property** (e.g. "turn on the light", "set brightness to 60") → go to Step 4
- **Run a scene** (e.g. "activate sleep mode") → go to Step 5
- **Natural language command via Xiao Ai speaker** → go to Step 6

If the intent is unclear, ask the user to clarify before proceeding.

---

### Step 2: List resources

#### List all devices (includes shared devices)

```bash
uvx mijiaAPI -l
```

Output includes each device's **name**, **model**, and **did** (device ID). Use device names in subsequent commands.

#### List homes

```bash
uvx mijiaAPI --list_homes
```

#### List scenes

```bash
uvx mijiaAPI --list_scenes
```

#### List consumable items (filters, bulbs, etc.)

```bash
uvx mijiaAPI --list_consumable_items
```

Show the output to the user in a readable format.

---

### Step 3: Get a device property

If the user doesn't know which property name to use, first look up the device spec:

```bash
# Replace MODEL with the model from --list_devices output (e.g. yeelink.light.lamp4)
uvx mijiaAPI --get_device_info MODEL
```

This prints all supported property names and actions for the device. Use the property name shown there.

Then get the value:

```bash
uvx mijiaAPI get --dev_name "DEVICE_NAME" --prop_name "PROP_NAME"
```

**Examples:**

```bash
# Get brightness of bedroom lamp
uvx mijiaAPI get --dev_name "卧室台灯" --prop_name "brightness"

# Get power state
uvx mijiaAPI get --dev_name "客厅灯" --prop_name "on"

# Get color temperature
uvx mijiaAPI get --dev_name "卧室台灯" --prop_name "color-temperature"
```

Report the result to the user in plain language (e.g. "The brightness is currently 60%").

---

### Step 4: Set a device property

If the property name is unknown, first run `--get_device_info MODEL` (see Step 3) to find the correct property name and its allowed values.

```bash
uvx mijiaAPI set --dev_name "DEVICE_NAME" --prop_name "PROP_NAME" --value VALUE
```

**Examples:**

```bash
# Turn on a device 开灯
uvx mijiaAPI set --dev_name "卧室台灯" --prop_name "on" --value True

# Turn off a device 关灯, “关闭书房台灯”
uvx mijiaAPI set --dev_name "书房台灯" --prop_name "on" --value False

# Set brightness (0–100)
uvx mijiaAPI set --dev_name "卧室台灯" --prop_name "brightness" --value 60

# Set color temperature
uvx mijiaAPI set --dev_name "卧室台灯" --prop_name "color-temperature" --value 4000

# Set fan speed
uvx mijiaAPI set --dev_name "空气净化器" --prop_name "fan-level" --value 2
```

Confirm success to the user. If the command fails with a value error, check allowed ranges using `--get_device_info`.

---

### Step 5: Run a scene

Scenes can be specified by name or ID (get the list with `--list_scenes`).

```bash
# Run one or more scenes by name or ID
uvx mijiaAPI --run_scene "SCENE_NAME_OR_ID"

# Run multiple scenes
uvx mijiaAPI --run_scene "睡眠模式" "晚安"
```

Confirm to the user which scene(s) were triggered.

---

### Step 6: Natural language command via Xiao Ai speaker

Use this only when the user wants to issue a command through a Xiao Ai (小爱) smart speaker.

```bash
# Send a natural language command (uses first available Xiao Ai speaker)
uvx mijiaAPI --run "PROMPT"

# Target a specific speaker
uvx mijiaAPI --run "PROMPT" --wifispeaker_name "SPEAKER_NAME"

# Silent execution (device obeys but speaker doesn't speak)
uvx mijiaAPI --run "PROMPT" --quiet
```

**Examples:**

```bash
uvx mijiaAPI --run "打开卧室台灯"
uvx mijiaAPI --run "把亮度调到50%"
uvx mijiaAPI --run "关闭所有灯" --quiet
uvx mijiaAPI --run "播放音乐" --wifispeaker_name "客厅小爱"
```

---

### Troubleshooting

**Login / QR code expired:**
- Re-run the command; a new QR code will be printed. Scan with the Mijia app.
- If auth persists across sessions, the token is cached at `~/.config/mijia-api/auth.json`.

**Device not found:**
- Run `uvx mijiaAPI -l` to verify the exact device name (names are case-sensitive, must match the Mijia app).
- For shared devices they should appear in the `-l` listing.

**Property name unknown:**
- Run `uvx mijiaAPI --get_device_info MODEL` with the device model from `-l` output.

**Value out of range / invalid:**
- Check allowed values with `--get_device_info MODEL` and retry with a valid value.

**Debug logging:**
```bash
MIJIA_LOG_LEVEL=DEBUG uvx mijiaAPI -l
```
