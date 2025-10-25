# PicoCalc + WebMite Quickstart

*(now with MMEdit, so you don’t have to suffer raw serial uploads)*

This README gets you from “Pico 2W in a calculator case” to “MMBasic in the browser,” plus a clean workflow using **MMEdit** for editing and file transfer.

---

## What is this?

* **PicoCalc**: A pocketable calculator-style device using a Raspberry Pi Pico/Pico W running **MMBasic**.
  → **[PicoCalc MMBasic page](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)**

* **PicoMite / WebMite**: Geoff Graham’s MMBasic firmware for the Pico family; WebMite adds a browser UI.
  → **[PicoMite User Manual (PDF)](https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf)**
  → **[WebMite overview](https://geoffg.net/webmite.html)**
  → **[PicoMite_Firmware.zip (UF2s)](https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip)**

* **MMEdit**: A purpose-built MMBasic editor + file manager + terminal for Windows (works great for PicoMite).
  → **[MMEdit](https://geoffg.net/mmedit.html)**

**Goal:** Flash **WebMite** on a **Pico 2W**, drop it into your PicoCalc, access MMBasic in a browser, and use **MMEdit** for real editing, transfers, and file management.

---

## Hardware

* Raspberry Pi **Pico 2W** (Wi-Fi variant required for WebMite)
* Your **PicoCalc** build (screen, keypad, power)
* USB data cable
* A computer (Windows recommended for MMEdit)

---

## Flash the firmware (UF2 drag-and-drop)

1. Download: **[PicoMite_Firmware.zip](https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip)**
   Pick the **Pico W / WebMite** UF2 inside.

2. Hold **BOOTSEL**, plug in Pico 2W (RPI-RP2 drive appears), drop the UF2 on it.
   It reboots into WebMite/MMBasic.

**PicoCalc wiring & display setup:** see **[PicoCalc MMBasic page](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)** and the **User Manual** for `OPTION LCDPANEL` and pin mappings.

---

## First contact: serial + browser

* **Serial (helpful for first setup):** 115200 8N1 on the Pico’s COM port.
* **Wi-Fi setup (STA):**
* **Wifi needs to be wpa2 or some older routers would work. **

  ```basic
  OPTION WIFI "YourSSID","YourPassphrase"
  SAVE
  REBOOT
  ```

  Then check your IP:

  ```basic
  PRINT MM.INFO(IP$)
  ```
* **Web UI:** Hit that IP in a browser for the WebMite page.
  Details: **[WebMite](https://geoffg.net/webmite.html)**

---

## Develop faster with MMEdit (editor, file transfer, file manager)

**MMEdit** removes the pain of manual uploads and gives you syntax-highlighting, a serial console, and on-device file management.

1. **Install MMEdit:**
   → **[MMEdit download & docs](https://geoffg.net/mmedit.html)**

2. **Target & connection:**

   * Launch MMEdit → set the **Target** to **PicoMite** (or PicoMiteVGA if that’s your build).
   * **Connection:** choose the Pico’s **COM port** at **115200** baud.
   * Click **Connect** (you’ll see the MMBasic prompt in MMEdit’s terminal pane).

3. **Edit & send code:**

   * Open or write your `.bas` in MMEdit’s editor.
   * Use **Send to MMBasic** (or **File → Send**) to upload the current program.
   * You can also **Save As** directly to the device using the **File Manager**.

4. **Manage files on the Pico:**

   * MMEdit’s **File Manager** lets you browse the Pico’s flash, upload/download, delete, and rename files.
   * Typical pattern:

     * Save your program as `AUTORUN.BAS` on the device.
     * In the console:

       ```basic
       OPTION AUTORUN ON
       SAVE
       REBOOT
       ```
     * Now it boots straight into your app.

5. **Terminal convenience:**

   * Use MMEdit’s terminal to `RUN`, `LIST`, `FILES`, etc.
   * **Ctrl+C** stops a running program.
   * Great for quick `OPTION` changes and debugging boot messages.

> Note: For WebMite, you’ll still love MMEdit for faster iteration over USB serial. Use the Web UI for remote convenience and demos, MMEdit for day-to-day dev speed.

---

## Minimal “prompt thing” (command router)

Make a tiny command runner so the keypad or web console can trigger utilities:

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
  DIM parts$() = SPLIT(cmd$," ")
  IF UBOUND(parts$) <> 2 THEN PRINT "usage: pin <num> <0|1>": RETURN
  p = VAL(parts$(1)) : v = VAL(parts$(2))
  PIN(p) = v
  PRINT "PIN(";p;") = ";v
RETURN

NetInfo:
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

Upload with MMEdit (Send → Save on device as `prompt.bas`), then:

```basic
OPTION AUTORUN ON
LOAD "prompt.bas"
SAVE
REBOOT
```

---

## Gotchas (quick fixes)

* **No Wi-Fi / no web page:** set `OPTION WIFI`, `SAVE`, `REBOOT`; verify with `MM.INFO(IP$)`.
* **Scrambled display:** confirm your `OPTION LCDPANEL` and pins per **PicoCalc MMBasic page** and the **User Manual**.
* **Autorun not working:** ensure filename is `AUTORUN.BAS` or you’ve `OPTION AUTORUN ON`.

---

## “Dumb-ass ideas” to ship before lunch

* **Web-Prompt buttons:** Tiny WebMite page with buttons that `PRINT` commands your prompt parses.
* **Pocket RF notes:** Log BSSIDs + timestamps to flash and export via MMEdit/File Manager.
* **Image-to-MMBasic logo:** Boot splash rendered with `LINE`/`PIXEL` so you need zero image files.
* **Ops deck:** Keypad modes—normal calc vs. ops panel (relay toggle, IP status, note macro).
* **Field CSV logger:** Sample analog pins, draw a sparkline, save CSV; pull the file with MMEdit.

Keep them small. Ten-minute prototypes are how empires begin.

---

## References (click these; they’re the good stuff)

* **PicoCalc MMBasic page:** [https://michaeladcock.info/temp/PicoCalc_MMBasic.html](https://michaeladcock.info/temp/PicoCalc_MMBasic.html)
* **PicoMite User Manual (PDF):** [https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf](https://geoffg.net/Downloads/picomite/PicoMite_User_Manual.pdf)
* **WebMite overview & docs:** [https://geoffg.net/webmite.html](https://geoffg.net/webmite.html)
* **PicoMite firmware bundle (UF2s):** [https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip](https://geoffg.net/Downloads/picomite/PicoMite_Firmware.zip)
* **MMEdit editor + file manager:** [https://geoffg.net/mmedit.html](https://geoffg.net/mmedit.html)

---

### Next moves

Flash WebMite, confirm the web UI, then switch to MMEdit for editing, uploads, and file management. After that, we can lock this into a repo with a tested MMEdit profile, example `prompt.bas`, and a short troubleshooting matrix for common PicoCalc displays.
