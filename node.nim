import config
import peer, topic

type
  NodeState* = object
    # These two are set when initialising the object and should only read
    # from after that.
    config*:             Config
    connectionStatus*:   ConnectionType

    # set of peers the node is connected to
    peers*:              seq[Peer]
    numPeers*:           Natural


    # The current subscribed to channels
    topics*:             seq[Topic]
    numTopics*:          Natural

  ConnectionType* = enum
    ctDisconnected, 
    ctConnected, 
    ctConnecting

proc initNodeState*(config: Config): NodeState =
  var ns: NodeState
  ns.config = config

  ns.topics = newSeq[Topic]()
  for tp in 0..ns.numTopics:
    var top = newTopic()
    ns.topics.add(top)

  ns.peers = newSeq[Peer]()
  for pr in 1..ns.numPeers:
    var peer = newPeer()
    ns.peers.add(peer)
  result = ns