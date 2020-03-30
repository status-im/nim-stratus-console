import cligen, sequtils, options, strutils, parseopt, chronos, json, times, tables
import
  nimcrypto/[bcmode, hmac, rijndael, pbkdf2, sha2, sysrand, utils, keccak, hash],
  eth/keys, eth/rlp, eth/p2p, eth/p2p/rlpx_protocols/[whisper_protocol],
  eth/p2p/[discovery, enode, peer_pool]

import fleets

var
  node: EthereumNode

# procedure for how to subscribe to a channel
proc subscribeChannel(
    channel: string, handler: proc (msg: ReceivedMessage) {.gcsafe.}) =
  var ctx: HMAC[sha256]
  var symKey: SymKey
  discard ctx.pbkdf2(channel, "", 65356, symKey)

  let channelHash = digest(keccak256, channel)
  var topic: array[4, byte]
  for i in 0..<4:
    topic[i] = channelHash.data[i]

  info "Subscribing to channel", channel, topic, symKey

  var filters = initTable[string, Filter]()
  let filter = initFilter(symKey = some(symKey), topics = @[topic])
  let filterId = filters.subscribeFilter(filter)

  discard node.subscribeFilter(filter, handler)

  
  while true:
    let messages = filters.getFilterMessages(filterId)
    if messages.len >= 1:
      echo "messages are", messages

proc handler(msg: ReceivedMessage) {.gcsafe.} =
  try:
    # ["~#c4",["dcasdc","text/plain","~:public-group-user-message",
    #          154604971756901,1546049717568,[
    #             "^ ","~:chat-id","nimbus-test","~:text","dcasdc"]]]
    let
      src =
        if msg.decoded.src.isSome(): $msg.decoded.src.get()
        else: ""
      payload = cast[string](msg.decoded.payload)
      data = parseJson(cast[string](msg.decoded.payload))
      channel = data.elems[1].elems[5].elems[2].str
      time = $fromUnix(data.elems[1].elems[4].num div 1000)
      message = data.elems[1].elems[0].str

    info "adding", full=(cast[string](msg.decoded.payload))
    # rootItem.add(channel, src[0..<8] & "..." & src[^8..^1], message, time)
  except:
    notice "no luck parsing", message=getCurrentExceptionMsg()

proc run(port: uint16 = 30303) =
  let address = Address(
    udpPort: port.Port, tcpPort: port.Port, ip: parseIpAddress("0.0.0.0"))

  let keys= newKeyPair()
  node = newEthereumNode(keys, address, 1, nil, addAllCapabilities = false)
  node.addCapability Whisper

  var bootnodes: seq[ENode] = @[]
  for nodeId in MainBootnodes:
    var bootnode: ENode
    discard initENode(nodeId, bootnode)
    bootnodes.add(bootnode)

  asyncCheck node.connectToNetwork(bootnodes, true, true)
  for nodeId in WhisperNodes:
    var whisperENode: ENode
    discard initENode(nodeId, whisperENode)
    var whisperNode = newNode(whisperENode)

    asyncCheck node.peerPool.connectToNode(whisperNode)

  node.protocolState(Whisper).config.powRequirement = 0

  subscribeChannel("test", handler)

dispatch(run)