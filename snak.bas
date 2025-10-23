' Snake_Vanilla.bas — works on minimal MMBasic (no MODE/FRAMEBUFFER needed)
' Controls: W/A/S/D = up/left/down/right ; P = pause ; Q = quit
' Flicker is minimized by only redrawing changed cells (head/tail/food).

OPTION DEFAULT INTEGER
OPTION ESCAPE OFF
RANDOMIZE TIMER

' === Grid and colors ===
CONST W = 320, H = 240       ' If your display is smaller, drawing will clip safely.
CONST CELL = 10
CONST COLS = W \ CELL
CONST ROWS = H \ CELL
CONST MAXLEN = 1024

' Colours
CONST COL_BG    = RGB(0,0,0)
CONST COL_GRID  = RGB(40,40,40)
CONST COL_SNAKE = RGB(0,200,60)
CONST COL_HEAD  = RGB(255,220,0)
CONST COL_FOOD  = RGB(220,50,50)
CONST COL_TEXT  = RGB(255,255,255)

' State
DIM snakeX(MAXLEN), snakeY(MAXLEN)
DIM INTEGER length, dx, dy, foodX, foodY, score, paused, alive, tick_ms

' Init
CLS
COLOUR COL_TEXT, COL_BG
score = 0
length = 5
FOR i = 0 TO length - 1
  snakeX(i) = COLS \ 2 - i
  snakeY(i) = ROWS \ 2
NEXT i
dx = 1 : dy = 0
paused = 0
alive = 1
tick_ms = 90

GOSUB DrawBackground
GOSUB DrawWholeSnake
GOSUB SpawnFood
GOSUB DrawFood
GOSUB DrawHUD

' Main loop
DO
  t0! = TIMER

  ' Input (WASD only, to avoid environment-dependent arrow codes)
  k$ = LCASE$(INKEY$)
  IF k$ <> "" THEN
    SELECT CASE k$
      CASE "a": IF dx <> 1  THEN dx = -1 : dy = 0
      CASE "d": IF dx <> -1 THEN dx =  1 : dy = 0
      CASE "w": IF dy <> 1  THEN dy = -1 : dx = 0
      CASE "s": IF dy <> -1 THEN dy =  1 : dx = 0
      CASE "p": paused = 1 - paused : GOSUB DrawHUD
      CASE "b": EXIT DO
    END SELECT
  ENDIF

  IF paused OR NOT alive THEN
    PAUSE 50
    ITERATE DO
  ENDIF

  ' Compute next head with wrap-around
  nx = (snakeX(0) + dx + COLS) MOD COLS
  ny = (snakeY(0) + dy + ROWS) MOD ROWS

  ' Self-collision?
  FOR i = 0 TO length - 1
    IF snakeX(i) = nx AND snakeY(i) = ny THEN alive = 0 : EXIT FOR
  NEXT i
  IF NOT alive THEN
    GOSUB DrawGameOver
    DO WHILE INKEY$ <> "" : LOOP
    DO: k$ = INKEY$ : LOOP WHILE k$ = ""
    EXIT DO
  ENDIF

  ' Save tail to erase later (if not eating)
  tx = snakeX(length - 1)
  ty = snakeY(length - 1)

  ' Shift body forward
  FOR i = length - 1 TO 1 STEP -1
    snakeX(i) = snakeX(i - 1)
    snakeY(i) = snakeY(i - 1)
  NEXT i
  snakeX(0) = nx : snakeY(0) = ny

  ' Food check
  ate = (nx = foodX AND ny = foodY)
  IF ate THEN
    length = length + 1
    score = score + 10
    IF tick_ms > 40 THEN tick_ms = tick_ms - 2
    GOSUB SpawnFood
    GOSUB DrawFood
    GOSUB DrawHUD
  ELSE
    ' erase old tail
    GOSUB EraseCell   ' uses tx, ty
  ENDIF

  ' Draw new head and former head body
  GOSUB DrawMove     ' paints body/head incrementally

  ' Pace
  dt! = TIMER - t0!
  IF dt! < 0 THEN dt! = 0
  wait_ms = tick_ms - INT(dt!)
  IF wait_ms > 0 THEN PAUSE wait_ms
LOOP

END

' ===================== Subs ======================

DrawBackground:
  COLOUR COL_BG, COL_BG : CLS
  ' Optional subtle grid
  COLOUR COL_GRID, COL_BG
  FOR gx = 0 TO W STEP CELL
    LINE gx, 0, gx, H
  NEXT gx
  FOR gy = 0 TO H STEP CELL
    LINE 0, gy, W, gy
  NEXT gy
RETURN

DrawWholeSnake:
  ' Draw body
  COLOUR COL_SNAKE, COL_BG
  FOR s = 1 TO length - 1
    x = snakeX(s) * CELL
    y = snakeY(s) * CELL
    BOX x, y, CELL, CELL
  NEXT s
  ' Head
  COLOUR COL_HEAD, COL_BG
  x = snakeX(0) * CELL
  y = snakeY(0) * CELL
  BOX x, y, CELL, CELL
RETURN

DrawMove:
  ' Paint previous head as body
  IF length > 1 THEN
    COLOUR COL_SNAKE, COL_BG
    x = snakeX(1) * CELL
    y = snakeY(1) * CELL
    BOX x, y, CELL, CELL
  ENDIF
  ' Paint new head
  COLOUR COL_HEAD, COL_BG
  x = snakeX(0) * CELL
  y = snakeY(0) * CELL
  BOX x, y, CELL, CELL
RETURN

EraseCell:
  COLOUR COL_BG, COL_BG
  x = tx * CELL
  y = ty * CELL
  BOX x, y, CELL, CELL
  ' Restore grid lines for that cell (cosmetic)
  COLOUR COL_GRID, COL_BG
  LINE x, y, x + CELL, y
  LINE x, y, x, y + CELL
  LINE x + CELL, y, x + CELL, y + CELL
  LINE x, y + CELL, x + CELL, y + CELL
RETURN

SpawnFood:
  DO
    foodX = INT(RND * COLS)
    foodY = INT(RND * ROWS)
    clash = 0
    FOR j = 0 TO length - 1
      IF snakeX(j) = foodX AND snakeY(j) = foodY THEN clash = 1 : EXIT FOR
    NEXT j
  LOOP WHILE clash
RETURN

DrawFood:
  COLOUR COL_FOOD, COL_BG
  x = foodX * CELL
  y = foodY * CELL
  BOX x, y, CELL, CELL
RETURN

DrawHUD:
  ' Simple HUD in the corner; redraw the text area
  COLOUR COL_BG, COL_BG
  BOX 0, 0, 160, 16
  COLOUR COL_TEXT, COL_BG
  TEXT 4, 2, "Score: " + STR$(score)
  IF paused THEN TEXT 90, 2, "PAUSED"
RETURN

DrawGameOver:
  COLOUR COL_BG, COL_BG : CLS
  COLOUR COL_TEXT, COL_BG
  TEXT W \ 2 - 40, H \ 2 - 10, "GAME OVER"
  TEXT W \ 2 - 60, H \ 2 + 12, "Score: " + STR$(score)
  TEXT W \ 2 - 92, H \ 2 + 32, "Press any key to exit"
RETURN
 