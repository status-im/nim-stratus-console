import strformat, strutils

type
  Module* = ref object
    moduleType*:     ModuleType
    numChannels*:    Natural
    useAmigaLimits*: bool

  ModuleType* = enum
    mtFastTracker,
    mtOctaMED,
    mtOktalyzer,
    mtProTracker,
    mtSoundTracker,
    mtStarTrekker,
    mtTakeTracker
