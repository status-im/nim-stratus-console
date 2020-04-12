import strformat, strutils

import illwill

import config
import renderer

type
  ViewType* = enum
    vtPattern, vtSamples, vtHelp

  TextColor = object
    fg: ForegroundColor
    hi: bool

  Theme = object
    rowNum:     TextColor
    rowNumHi:   TextColor
    note:       TextColor
    noteNone:   TextColor
    sample:     TextColor
    sampleNone: TextColor
    effect:     TextColor
    effectNone: TextColor
    border:     TextColor
    muted:      TextColor
    text:       TextColor
    textHi:     TextColor
    cursor:     TextColor
    cursorBg:   BackgroundColor

include themes

var gCurrTheme = themes[0]

proc setTheme*(n: Natural) =
  if n <= themes.high:
    gCurrTheme = themes[n]

template setColor(tb: var TerminalBuffer, t: TextColor) =
  tb.setForegroundColor(t.fg)
  if t.hi:
    tb.setStyle({styleBright})
  else:
    tb.setStyle({})

proc drawCell(tb: var TerminalBuffer, x, y: Natural, cell: Cell, muted: bool) =
  var
    note = noteToStr(cell.note)
    effect = effectToStr(cell.effect.int)

    s1 = (cell.sampleNum and 0xf0) shr 4
    s2 =  cell.sampleNum and 0x0f
    sampleNum = nibbleToChar(s1.int) & nibbleToChar(s2.int)

  if muted:
    tb.setColor(gCurrTheme.muted)

  if not muted:
    if cell.note == NOTE_NONE:
      tb.setColor(gCurrTheme.noteNone)
    else:
      tb.setColor(gCurrTheme.note)

  tb.write(x, y, note)

  if not muted:
    if cell.sampleNum == 0:
      tb.setColor(gCurrTheme.sampleNone)
    else:
      tb.setColor(gCurrTheme.sample)

  tb.write(x+4, y, sampleNum)

  if not muted:
    if cell.effect == 0:
      tb.setColor(gCurrTheme.effectNone)
    else:
      tb.setColor(gCurrTheme.effect)

  tb.write(x+7, y, effect)

const
  SCREEN_X_PAD = 2
  SCREEN_Y_PAD = 1
  VIEW_Y = 6
  PATTERN_HEADER_HEIGHT = 3
  PATTERN_TRACK_WIDTH = 10

proc drawChannelState*(tb: var TerminalBuffer, cs: ChannelState, viewHeight: Natural) =
  const
    x1 = SCREEN_X_PAD
    y1 = VIEW_Y

    NUM_X      = x1+1
    NAME_X     = NUM_X + 2 + 2
    LENGTH_X   = NAME_X + SAMPLE_NAME_LEN-1 + 2
    FINETUNE_X = LENGTH_X + 5 + 2
    VOLUME_X   = FINETUNE_X + 2 + 2
    REPEAT_X   = VOLUME_X + 2 + 2
    REPLEN_X   = REPEAT_X + 5 + 2

    x2 = REPLEN_X + 5 + 2 - 1

  let y2 = y1 + viewHeight-1

  var bb = newBoxBuffer(tb.width, tb.height)

  # Draw border
  bb.drawVertLine(x1, y1, y2)
  bb.drawVertLine(x2, y1, y2)
  bb.drawHorizLine(x1, x2, y1)
  bb.drawHorizLine(x1, x2, y2)

proc drawScreen(tb: var TerminalBuffer, ps: ChannelState) =
  drawPlaybackState(tb, ps)
  drawStatusLine(tb)

  let viewHeight = max(tb.height - VIEW_Y - 3, 0)

  case gCurrView
  of vtPattern: drawPatternView(tb, ps, viewHeight)
  of vtSamples: drawSamplesView(tb, ps, viewHeight)
  of vtHelp:    drawHelpView(tb, viewHeight)

  if ps.paused:
    drawPauseOverlay(tb, ps, viewHeight)


proc updateScreen*(ps: PlaybackState, forceRedraw: bool = false) =
  var (w, h) = terminalSize()

  if gTerminalBuffer == nil or gTerminalBuffer.width != w or
                               gTerminalBuffer.height != h:
    gTerminalBuffer = newTerminalBuffer(w, h)
  else:
    gTerminalBuffer.clear()

  drawScreen(gTerminalBuffer, ps)

  if forceRedraw and hasDoubleBuffering():
    setDoubleBuffering(false)
    gTerminalBuffer.display()
    setDoubleBuffering(true)
  else:
    gTerminalBuffer.display()
