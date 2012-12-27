(->
  _level = 0
  _id = 0
  _handlers = {}
  _gk_instances = {}

  _matchesSelector = (el, selector, bound_el) ->
    getMatcher = (el) ->
      matcher = undefined

      return matcher if matcher

      matcher ?= el.matches
      matcher ?= el.webkitMatchesSelector

      throw new Error 'There is no mache element' if matcher is undefined

      matcher

    return bound_el if selector is '_root'

    return if el is bound_el

    return el if getMatcher(el).call el, selector

    if el.parentNode
      _level++
      _matchesSelector el.parentNode, selector, bound_el

  _addHandler = (gk, evt, selector, cb) ->
    _handlers[gk.id] ?= {}
    _handlers[gk.id][evt] ?= {}
    _handlers[gk.id][evt][selector] ?= []

    _handlers[gk.id][evt][selector].push cb

  _removeHandler = (gk, evt, selector, cb) ->
    if not cb and not selector
      _handlers[gk.id][evt] = {}
      return

    unless cb
      delete _handlers[gk.id][evt][selector]
      return

    i = 0
    handlerLen = _handlers[gk.id][evt][selector].length

    while i < handlerLen
      if _handlers[gk.id][evt][selector][i] is cb
        _handlers[gk.id][evt][selector].pop i, 1
        break
      i++

  _handleEvent = (id, e, type) ->
    return unless _handlers[id][type]

    target = e.target
    selector = undefined
    match = undefined
    matches = {}
    i = 0
    j = 0
    _level = 0
    cancel = (e) ->
      e.preventDefault()
      e.stopPropagation()
    selectors = Object.keys _handlers[id][type]

    selectors.forEach (selector) ->
      match = _matchesSelector target, selector, _gk_instances[id].element
      matchesEvent = -> return true

      if match and matchesEvent type, _gk_instances[id].element, match, selector is '_root', e
        _level++
        _handlers[id][type][selector].match = match
        matches[_level] = _handlers[id][type][selector]

    e.stopPropagation = -> e.cancelBubble = true

    i = 0
    while i <= _level
      if matches[i]
        j = 0
        matchLen = matches[i].length
        while j < matchLen
          if matches[i][j]? and matches[i][j].call(matches[i].match, e) is false
            cancel e
            return

          return if e.cancelBubble
          j++
      i++

  _bind = (evt, selector, cb, remove) ->
    checkType = (type, arg) ->
      object = Object::toString.call(arg).slice 8, -1

      if arg? and object is type then true else false

    addEvent = (gk, type, cb) ->
      use_capture = type is 'blur' or type is 'focus'
      gk.element.addEventListener type, cb, use_capture

    evt = [evt] unless checkType 'Array', evt

    if not cb and checkType 'Function', selector
      cb = selector
      selector = '_root'

    id = @id
    global_cb = (e) -> _handleEvent id, e, global_cb.original

    i = undefined
    i = 0
    evLen = evt.length

    while i < evLen
      global_cb.original = evt[i]

      if not _handlers[@id] or not _handlers[@id][evt[i]]
        addEvent @, evt[i], global_cb

      if remove
        _removeHandler @, evt[i], selector, cb

      _addHandler @, evt[i], selector, cb
      i++
    @

  class Gk
    constructor: (el, id) ->
      unless @ instanceof Gk
        for key of _gk_instances
          return _gk_instances[key] if _gk_instances[key].element is el

        _id++
        _gk_instances[_id] = new Gk el, _id

        return _gk_instances[_id]

      @element= el
      @id = _id
    on: (evt, selector, cb) ->
      _bind.call @, evt, selector, cb
    off: (evt, selector, cb) ->
      _bind.call @, evt, selector, cb, true

  window.Gk = Gk
)()
