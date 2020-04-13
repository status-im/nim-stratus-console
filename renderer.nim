import math, strformat

import config
import module

type
  NodeState* = object
    # These two are set when initialising the object and should only read
    # from after that.
    config*:             Config
    module*:             Module

    # The mute state of the channels can be set from the outside
    channels*:           seq[Channel]

  Channel* = object
    # Can be set from the outside to mute/unmute channels
    state*:          ChannelState

  ChannelState* = enum
    csPlaying, csMuted, csDimmed

proc initNodeState*(config: Config, module: Module): NodeState =
  var ns: NodeState
  ns.config = config
  ns.module = module

#   ns.channels = newSeq[Channel]()
#   for ch in 0..<module.numChannels:
#     var chan = initChannel()
#     ns.channels.add(chan)


  result = ns