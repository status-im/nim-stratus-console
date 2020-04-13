type
  Topic* = ref object
    # Can be set from the outside to mute/unmute channels
    state*:          TopicState
    name*:           string

  TopicState* = enum
    tsActive, tsMuted, tsUnread

proc newTopic*(): Topic = 
  result = new Topic  
