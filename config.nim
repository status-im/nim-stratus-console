import logging, parseopt, parseutils, strformat, strutils

const VERSION = "1.0.0"

type
  Config* = object
    startPos*:         Natural
    startRow*:         Natural
    theme*:            Natural
    displayUI*:        bool
    refreshRateMs*:    Natural
    suppressWarnings*: bool
    verboseOutput*:    bool

proc initConfigWithDefaults(): Config =
  result.startPos         = 0
  result.startRow         = 0
  result.theme            = 1
  result.displayUI        = true
  result.refreshRateMs    = 20
  result.suppressWarnings = false
  result.verboseOutput    = false

proc printVersion() =
  echo "nim-mod version " & VERSION
  echo "Copyright (c) 2016-2018 by John Novak"


proc printHelp() =
  printVersion()
  echo """
Usage: nim-mod [OPTIONS] FILENAME

Options:

  USER INTERFACE
    -t, --theme=INTEGER       select theme, must be between 1 and 7;
                              default is 1
    -u, --noUserInterface     do not show the user interface
    -R, --refreshRate=INTEGER set UI refresh rate in millis; default is 20

  MISC
    -h, --help                show this help
    -v, --version             show version information
    -V, --verbose             verbose output (for debugging)
    -q, --quiet               suppress warnings
"""


proc invalidOptValue(opt: string, val: string, msg: string) {.noconv.} =
  echo fmt"Error: value '{val}' for option -{opt} is invalid:"
  echo fmt"    {msg}"
  quit(QuitFailure)

proc missingOptValue(opt: string) {.noconv.} =
  echo fmt"Error: option -{opt} requires a parameter"
  quit(QuitFailure)

proc invalidOption(opt: string) {.noconv.} =
  echo fmt"Error: option -{opt} is invalid"
  quit(QuitFailure)


proc parseCommandLine*(): Config =
  var
    config = initConfigWithDefaults()
    optParser = initOptParser()

  for kind, opt, val in optParser.getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case opt
      # "Hidden" feature for testing & debuggin only
      # (it doesn't do channel/pattern state chasing)
      of "startPos", "p":
        if val == "": missingOptValue(opt)
        else:
          var
            pos = val.split(':')
            startPos, startRow: int

          if pos.len != 2 or
             parseInt(pos[0], startPos) == 0 or
             parseInt(pos[1], startRow) == 0:
            invalidOptValue(opt, val,
                            "song position must be in INT:INT format")
          config.startPos = startPos
          config.startRow = startRow

      of "theme", "t":
        if val == "": missingOptValue(opt)
        var t: int
        if parseInt(val, t) == 0:
          invalidOptValue(opt, val, "invalid theme number")
        if t < 1 or t > 7:
          invalidOptValue(opt, val, "theme number must be between 1 and 7")
        config.theme = t-1

      of "noUserInterface", "u":
        config.displayUI = false

      of "refreshRate", "R":
        if val == "": missingOptValue(opt)
        var rate: int
        if parseInt(val, rate) == 0:
          invalidOptValue(opt, val, "refresh rate must be a positive integer")
        if rate > 0: config.refreshRateMs = rate
        else:
          invalidOptValue(opt, val, "refresh rate must be a positive integer")

      of "help",    "h": printHelp();    quit(QuitSuccess)
      of "version", "v": printVersion(); quit(QuitSuccess)

      of "verbose", "V":
        config.verboseOutput = true

      of "quiet", "q":
        config.suppressWarnings = true

      else: invalidOption(opt)

    of cmdEnd: assert(false)

  result = config

