# PicoCalc + WebMite Quickstart (a.k.a. “yes, you *can* turn that tiny calculator into a tiny web computer”)

This README gets you from “staring at a Pico 2W and a calculator case” to “serving MMBasic from a browser.” It’s opinionated, trimmed of fluff, and packed with links.

---

## What is this?

* **PicoCalc**: A pocketable calculator-style device powered by a Raspberry Pi Pico / Pico W running **MMBasic** (the “PicoMite” port). It’s basically a tiny stand-alone BASIC computer with GPIO.
  • Reference: **[PicoCalc MMBasic page](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)**

* **PicoMite / WebMite**: Geoff Graham’s MMBasic firmware for the Raspberry Pi Pico family.
  • User manual: **[PicoMite User Manual (PDF)](https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf)**
  • Firmware bundle: **[PicoMite_Firmware.zip](https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip)**
  • WebMite overview & docs: **[WebMite](https://geoffg.net/webmite.html)**

**Goal:** Put **WebMite** on a **Raspberry Pi Pico 2W**, drop it into a PicoCalc build, and use a browser to talk to MMBasic.

---

## Hardware you’ll want

* Raspberry Pi **Pico 2W** (the Wi-Fi variant is required for WebMite).
* Your **PicoCalc** build (screen, keypad, power—whatever kit/variant you’re using).
* USB cable (data capable).
* A computer with a browser and a serial terminal (for first-boot config if needed).

---

## Firmware flashing (drag-and-drop, no wizard hats required)

1. **Download firmware**
   Grab Geoff’s firmware pack: **[PicoMite_Firmware.zip](https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip)**
   Inside you’ll find UF2 files for different targets. Use the one matching **Pico W / WebMite** (the filename typically mentions “PicoW” or “WebMite”).

2. **Boot the Pico 2W into USB mode**

   * Hold the **BOOTSEL** button on the Pico.
   * Plug it into your computer via USB.
   * Release BOOTSEL when a new drive (RPI-RP2) appears.

3. **Flash it**

   * Drag the correct **.uf2** onto the RPI-RP2 drive.
   * The Pico reboots itself into WebMite/MMBasic.

> If you’re building the **PicoCalc**, see **[PicoCalc MMBasic page](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)** for wiring, display, and key matrix details.

---

## First contact: console & browser

* **Serial console (optional but handy):**
  Use a terminal at **115200 8N1** to watch boot logs, set options, and type MMBasic directly.

* **Web UI (the “WebMite” bit):**
  After boot, WebMite starts an access point or joins your Wi-Fi (depending on `OPTION WIFI` you set).

  * If AP mode: connect your computer/phone to the Pico’s SSID, then browse to the default IP (see boot messages).
  * If STA mode: set credentials and join your network:

    ```basic
    OPTION WIFI "YourSSID","YourPassphrase"
    SAVE
    REBOOT
    ```
  * Now hit the device’s IP in your browser for the WebMite page.
    Full details live here: **[WebMite docs](https://geoffg.net/webmite.html)**

---

## MMBasic essentials (two minutes to competence)

* **Edit/run code:**

  ```basic
  NEW
  10 PRINT "Hello PicoCalc!"
  20 GOTO 10
  RUN
  ```
* **Stop a running program:** Press **Ctrl+C** (or the on-device key mapped to break).
* **List / save / load:**

  ```basic
  LIST
  SAVE "main.bas"
  LOAD "main.bas"
  ```
* **GPIO taste test:**

  ```basic
  PIN(25) = 1    ' blink onboard LED (check your PicoCalc wiring)
  PAUSE 500
  PIN(25) = 0
  ```

Everything else is in the **[PicoMite User Manual](https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf)**. It’s surprisingly readable.

---

## The “prompt thing” (turn PicoCalc into a tiny command runner)

You can make a lightweight, text-prompt front end—type commands on the keypad or over the web console, dispatch little utilities, and print results. Here’s a minimal pattern you can riff on:

```basic
OPTION AUTORUN ON
' prompt.bas — tiny command router for PicoCalc/WebMite

DIM cmd$ = ""
DO
  PRINT "> ";
  LINE INPUT cmd$
  cmd$ = LCASE$(TRIM$(cmd$))

  IF cmd$ = "help" THEN GOSUB Help
  IF LEFT$(cmd$,3) = "pin" THEN GOSUB PinCmd
  IF cmd$ = "net" THEN GOSUB NetInfo
  IF cmd$ = "temp" THEN GOSUB Temp
  IF cmd$ = "about" THEN GOSUB About

LOOP

Help:
  PRINT "help   - this menu"
  PRINT "pin N V - set pin N to value V (0/1)"
  PRINT "temp   - read internal temp (if supported)"
  PRINT "net    - show Wi-Fi/ip info"
  PRINT "about  - firmware info"
RETURN

PinCmd:
  ' e.g., "pin 25 1"
  DIM parts$() = SPLIT(cmd$," ")
  IF UBOUND(parts$) <> 2 THEN PRINT "usage: pin <num> <0|1>": RETURN
  p = VAL(parts$(1)) : v = VAL(parts$(2))
  PIN(p) = v
  PRINT "PIN(";p;") = ";v
RETURN

NetInfo:
  ' WebMite exposes info via MM.INFO and OPTIONs
  PRINT "IP: "; MM.INFO(IP$)
  PRINT "MAC:"; MM.INFO(MAC$)
RETURN

Temp:
  PRINT "Temp: "; MM.TEMP; " C"
RETURN

About:
  PRINT MM.INFO$(VERSION$)
  PRINT MM.INFO$(CPUSPEED)
RETURN
```

Drop this into `prompt.bas`, `SAVE`, then `OPTION AUTORUN ON` if you want it to boot straight into your prompt.

---

## Gotchas & fixes (so you don’t rage-reflash at 2 a.m.)

* **“It boots but I don’t see Wi-Fi.”**
  Set Wi-Fi credentials explicitly:

  ```basic
  OPTION WIFI "YourSSID","YourPassphrase"
  SAVE : REBOOT
  ```

  Then check `MM.INFO(IP$)`.

* **Display looks scrambled.**
  Verify your PicoCalc display settings (driver, pins, rotations) per **[PicoCalc MMBasic page](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)** and the **User Manual**’s `OPTION LCDPANEL`.

* **Programs won’t autorun.**
  Ensure the filename and option:

  ```basic
  SAVE "AUTORUN.BAS"
  OPTION AUTORUN ON
  REBOOT
  ```

* **Lockups / weirdness.**
  Power matters. Give the PicoCalc clean 5V (or solid battery + regulator). USB hubs can be noisy gremlins.

---

## “Dumb-ass ideas” (a.k.a. excellent excuses to tinker)

* **Web-Prompt Launcher:** A single-page WebMite UI with buttons mapped to `PRINT`ed commands that your `prompt.bas` parses. Tap “Scan Keys,” “LED Test,” “Log Sensor,” etc., from your phone.

* **Pocket RF Notes:** Use the keypad to tag Wi-Fi BSSIDs you see in the field; store timestamps and simple notes to flash. Later, dump via the web console and correlate in Splunk.

* **Image-to-MMBasic art:** Convert small images into MMBasic `LINE`/`PIXEL` draws for the PicoCalc display. Great for boot logos and status glyphs.

* **Calculator-plus:** Keep normal calc functions, but add “Ops” mode where the keypad becomes a command deck for your home lab (send serial strings, toggle GPIO relays, show IP/health).

* **Offline Field Logger:** Sample a couple of analog pins, show sparkline charts on the LCD, save CSV to flash, and serve downloads via WebMite.

Each of these is tiny on purpose. Build a 10-minute prototype, then harden what’s fun.

---

## Reference links (all the things)

* **PicoCalc MMBasic page:** [https://michaeladcock.info/temp/PicoCalc_MMBasic.html](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)
* **PicoMite User Manual (PDF):** [https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf](https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf)
* **WebMite overview & docs:** [https://geoffg.net/webmite.html](https://geoffg.net/webmite.html)
* **PicoMite firmware bundle (UF2s):** [https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip](https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip)

---

## Next moves

* Flash WebMite on the Pico 2W, confirm the web UI, and drop in the `prompt.bas` router.
* Once your display and keypad are talking, wire a couple of “Ops” commands—LED test, IP status, quick notes—to prove the loop.
* When you’re ready, we can harden this into a tidy repo with a `docs/` folder, a reproducible UF2 pick, and a minimal test matrix for common PicoCalc builds.
