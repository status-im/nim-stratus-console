import strformat, strutils

import illwill

import config, module
import renderer

type
  ViewType* = enum
    vtNode, vtSamples, vtHelp

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

const
  SCREEN_X_PAD = 2
  SCREEN_Y_PAD = 1
  VIEW_Y = 6
  PATTERN_HEADER_HEIGHT = 3
  PATTERN_TRACK_WIDTH = 10

var
  gCurrView = vtNode
  gLastView: ViewType

proc setCurrView*(view: ViewType) =
  gCurrView = view

proc currView*: ViewType = gCurrView

proc toggleHelpView*() =
  if gCurrView == vtHelp:
    gCurrView = gLastView
  else:
    gLastView = gCurrView
    gCurrView = vtHelp

var gTerminalBuffer: TerminalBuffer

proc drawNodeState*(tb: var TerminalBuffer, ns: NodeState) =
  const
    x1 = SCREEN_X_PAD
    y1 = VIEW_Y

    NUM_X      = x1+1
    NAME_X     = NUM_X + 2 + 2
    LENGTH_X   = NAME_X
    FINETUNE_X = LENGTH_X + 5 + 2
    VOLUME_X   = FINETUNE_X + 2 + 2
    REPEAT_X   = VOLUME_X + 2 + 2
    REPLEN_X   = REPEAT_X + 5 + 2

    x2 = REPLEN_X + 5 + 2 - 1

  let y2 = y1 + max(tb.height - VIEW_Y - 3, 0)

  var bb = newBoxBuffer(tb.width, tb.height)

  # Draw border
  bb.drawVertLine(x1, y1, y2)
  bb.drawVertLine(x2, y1, y2)
  bb.drawHorizLine(x1, x2, y1)
  bb.drawHorizLine(x1, x2, y2)

  tb.setColor(gCurrTheme.border)
  tb.write(bb)

var gHelpViewText: TerminalBuffer

var gStartHelpLine = 0

proc scrollHelpViewUp*() =
  gStartHelpLine = max(gStartHelpLine - 1, 0)

proc scrollHelpViewDown*() =
  inc(gStartHelpLine)

proc createHelpViewText() =
  var
    y = 0
    xPad = 15

  proc writeEntry(key: string, desc: string) =
    gHelpViewText.setColor(gCurrTheme.textHi)
    gHelpViewText.write(0, y, key)
    gHelpViewText.setColor(gCurrTheme.text)
    gHelpViewText.write(xPad, y, desc)
    inc(y)

  gHelpViewText.setColor(gCurrTheme.note)
  gHelpViewText.write(0, y, "GENERAL")
  inc(y, 2)

  writeEntry("?", "toggle help view")
  writeEntry("ESC", "exit help view")
  writeEntry("UpArrow, K", "scroll view up (sample & help view)")
  writeEntry("DownArrow, J", "scroll view down (sample & help view)")
  writeEntry("V", "toggle pattern/sample view")
  writeEntry("Tab", "next track page (pattern view)")
  writeEntry("F1-F7", "set theme")
  writeEntry("R", "force redraw screen")
  writeEntry("Q", "quit")
  inc(y)

  gHelpViewText.setColor(gCurrTheme.note)
  gHelpViewText.write(0, y, "PLAYBACK")
  inc(y, 2)

  writeEntry("SPACE", "pause playback")
  writeEntry("LeftArrow, H", "jump 1 song position backward")
  writeEntry("Shift+H", "jump 10 song positions backward")
  writeEntry("RightArrow, L", "jump 1 song position forward")
  writeEntry("Shift+L", "jump 10 song positions forward")
  writeEntry("G", "jump to first song position")
  writeEntry("Shift+G", "jump to last song position")
  inc(y)

  gHelpViewText.setColor(gCurrTheme.note)
  gHelpViewText.write(0, y, "SOUND OUTPUT")
  inc(y, 2)

  xPad = 6
  writeEntry("1-9", "toggle mute channels 1-9")
  writeEntry("0", "toggle mute channel 10")
  writeEntry("U", "unmute all channels")
  writeEntry(",", "decrease amp gain")
  writeEntry(".", "increase amp gain")
  writeEntry("[", "decrease stereo width")
  writeEntry("]", "increase stereo width")
  writeEntry("I", "toggle resampler algorithm")
  inc(y)

proc drawHelpView*(tb: var TerminalBuffer, viewHeight: Natural) =
  if viewHeight < 2: return

  const
    WIDTH = 56
    x1 = SCREEN_X_PAD
    y1 = VIEW_Y
    x2 = x1 + WIDTH

  let
    y2 = y1 + viewHeight-1

  var bb = newBoxBuffer(tb.width, tb.height)

  # Draw border
  bb.drawVertLine(x1, y1, y2)
  bb.drawVertLine(x2, y1, y2)
  bb.drawHorizLine(x1, x2, y1)
  bb.drawHorizLine(x1, x2, y2)

  tb.setColor(gCurrTheme.border)
  tb.write(bb)

  var x = x1+2
  var y = y1+1

  gHelpViewText = newTerminalBuffer(WIDTH-2, 32)
  createHelpViewText()  # could be suboptimal with long texts, but in reality
                        # doesn't really matter...
  let
    numLines = gHelpViewText.height
    numVisibleLines = max(viewHeight-2, 0)

  if gStartHelpLine + numVisibleLines >= numLines:
    gStartHelpLine = max(numLines - numVisibleLines, 0)

  tb.copyFrom(gHelpViewText, 0, gStartHelpLine, WIDTH, numVisibleLines, x, y)


proc drawStatusLine(tb: var TerminalBuffer) =
  if tb.height >= 9:
    tb.setColor(gCurrTheme.text)
    tb.write(SCREEN_X_PAD+1, tb.height - SCREEN_Y_PAD-1, "Press ")
    tb.setColor(gCurrTheme.textHi)
    tb.write("?")
    tb.setColor(gCurrTheme.text)
    tb.write(" for help, ")
    tb.setColor(gCurrTheme.textHi)
    tb.write("Q")
    tb.setColor(gCurrTheme.text)
    tb.write(" to quit")


proc drawScreen(tb: var TerminalBuffer, ns: NodeState) =
  drawNodeState(tb, ns)
  drawStatusLine(tb)

  let viewHeight = max(tb.height - VIEW_Y - 3, 0)

  case gCurrView
  of vtNode:    discard
  of vtSamples: discard # drawSamplesView(tb, ns, viewHeight)
  of vtHelp:    drawHelpView(tb, viewHeight)


proc updateScreen*(ns: NodeState, forceRedraw: bool = false) =
  var (w, h) = terminalSize()

  if gTerminalBuffer == nil or gTerminalBuffer.width != w or
                               gTerminalBuffer.height != h:
    gTerminalBuffer = newTerminalBuffer(w, h)
  else:
    gTerminalBuffer.clear()

  drawScreen(gTerminalBuffer, ns)

  if forceRedraw and hasDoubleBuffering():
    setDoubleBuffering(false)
    gTerminalBuffer.display()
    setDoubleBuffering(true)
  else:
    gTerminalBuffer.display()
