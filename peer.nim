type
  Peer* = ref object
    peerType*:    PeerType
    enode*:       string

  PeerType* = enum
    ptWaku,
    ptWhisper,
    ptMailserver,
    ptLight

proc newPeer*(): Peer = 
  result = new Peer