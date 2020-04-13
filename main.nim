import logging, os

import illwill

import config
import display
import node

proc nodeQuitProc() {.noconv.} =
  illwillDeinit()

proc startNode(config: Config) =
  var ns = initNodeState(config)

  system.addQuitProc(nodeQuitProc)


  if config.displayUI:
    illwillInit(fullscreen = true)
    hideCursor()
    setTheme(config.theme)
  else:
    illwillInit(fullscreen = false)

  while true:
    let key = getKey()
    case key:
    of Key.QuestionMark: toggleHelpView()

    of Key.Escape:
      if currView() == vtHelp: toggleHelpView()

    of Key.V:
      case currView()
      of vtNode:    setCurrView(vtNode)
      of vtSamples: discard # setCurrView(vtNode)
      of vtHelp:    discard

    of Key.Up, Key.K:
      case currView()
      of vtNode:    setCurrView(vtNode)
      of vtSamples: discard 
      of vtHelp:    scrollHelpViewUp()

    of Key.Down, Key.J:
      case currView()
      of vtNode:    setCurrView(vtNode)
      of vtSamples: discard
      of vtHelp:    scrollHelpViewDown()

    of Key.Left, Key.H:
      discard

    of Key.ShiftH:
      discard

    of Key.Right, Key.L:
      discard

    of Key.ShiftL:
      discard

    of Key.G:      discard
    of Key.ShiftG: discard

    of Key.F1: setTheme(0)
    of Key.F2: setTheme(1)
    of Key.F3: setTheme(2)
    of Key.F4: setTheme(3)
    of Key.F5: setTheme(4)
    of Key.F6: setTheme(5)
    of Key.F7: setTheme(6)

    of Key.Tab:   discard

    of Key.Q: quit(QuitSuccess)

    of Key.R:
      if config.displayUI:
        illwillInit(fullscreen = true)
        hideCursor()
        updateScreen(ns, forceRedraw = true)

    else: discard

    if config.displayUI:
      updateScreen(ns)

    sleep(config.refreshRateMs)

proc main() =
  var logger = newConsoleLogger(fmtStr = "")
  addHandler(logger)
  setLogFilter(lvlNotice)

  var config = parseCommandLine()

  if config.verboseOutput:
    setLogFilter(lvlDebug)
  elif config.suppressWarnings:
    setLogFilter(lvlError)

  startNode(config)

main()
