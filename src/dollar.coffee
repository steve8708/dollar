# Dollar.coffee (alpha)
#
# The most bang for your buck!
#
# Work in progress...

# Setup - - - - - - - - - - - - - - - - - - - - - - - - - -

original$ = window.$


# Main Class - - - - - - - - - - - - - - - - - - - - - - - -

# FIXME: maybe move to be real coffeescript class
# class $
# $ = (selector, context) ->
#   new $.fn.init selector, context

$ = (selector, context) ->
  new $.fn.init selector, context

expando = $.expando = 'dollar-' + Date.now()
expandoData = {}

$.fn = $:: =
  constructor: $

  init: (selector, context) ->
    context ?= document
    @context = context
    @selector = selector or ''
    return @ if not selector

    els = []
    if typeof selector is 'string'
      # Optimize the ish out of id querying
      if /^#[a-z0-9]+$/i.test selector
        match = context.getElementById selector.substring 1
        if match then @[0] = match ; @length = 1 ; return
        else @length = 0 ; return @
      else if /^\.[a-z0-9]+$/i.test selector
        els = context.getElementsByClassName selector.substring 1
      else if /^[^\.|\[|<]+$/i.test selector
        els = context.getElementsByTagName selector
      else if not /^\s*</g.test selector
        els = context.querySelectorAll selector
      else
        el = document.createElement 'div'
        el.innerHTML = selector
        els = el.children

    else if selector instanceof $
      return selector
    else if typeof selector is 'function'
      return @ready selector
    else
      selectorIsntWindow = selector isnt window
      if selector.length? and not isStringLike(selector) and selectorIsntWindow
        if selector.length
          els = $.unique $.flatten selector
      else
        els[0] = selector

    @[index] = el for el, index in els
    @length = els.length

  hide:      -> el and el.style.display = 'none' for el in @ ; @
  last:      -> $ @[@length - 1]
  show:      -> el and el.style.display = '' for el in @ ; @
  first:     -> $ @[0]
  clone:     -> $ @map (el) -> el.cloneNode true if el
  empty:     -> el.innerHTML = '' for el in @ ; @
  remove:    -> @off() and @detach()
  contents:  -> $ ( @[0].childNodes )

  eq:         (index)     -> $ @[index]
  get:        (index)     -> if index? then @[index] else [].slice.call @
  each:       (fn)        -> fn.call @, index, el for el, index in @
  map:        (callback)  -> $ [].map.call @, callback
  not:        (selector)  -> not @is selector
  find:       (selector)  -> $ selector, @[0]
  grep:       (fn)        -> [].filter.call @, fn
  removeAttr: (name)      -> el.removeAttribute name for el in @ ; @

  detach: ->
    for el in @
      continue if not el
      el.parentNode.removeChild el if el and el.parentNode
    @

  # FIXME: support add(selector), add(html), add(jquery object)
  add: (items...) ->
    for item in items
      continue if not item
      $item = $ item
      @push el for el in $item
    @

  val: (value) ->
    unless value? then return @[0] and @[0].value or ''
    else el and el.value = value for el in @
    @

  prop: (name, value) ->
    unless value? then return ( @[0][name] if @[0] )
    else el[name] = value for el in @
    @

  addClass: (className, el) ->
    return @ if /^\s*$/.test className
    for el in @
      el.className += " " + className if not @hasClass className, el
    @

  toggleClass: (className) ->
    for el in @
      if @hassClass className, el then $(el).removeClass className
      else $(el).addClass className
    @

  hasClass: (className, el) ->
    el ?= @[0]
    !! el.className.match new RegExp "(?:\\s|^)#{className}(?:\\s|$)"

  removeClass: (className, el) ->
    for el in @
      re = new RegExp "(?:\\s+|^)#{className}(?:\\s+|$)"
      el.className = el.className.replace re, ' '
    @

  html: (html) ->
    el = @[0]
    if not html? then return el and el.innerHTML
    el and el.innerHTML = html
    @

  text: (text) ->
    if text? then return @[0] and @[0].textContent or ''
    else @[0].textContent = text
    @

  # FIXME: support namespaces
  # FIXME: support ms opposite of attachevent
  off: (events, selector, handler) ->
    # FIXME: support off() off(fn) off(namespace) off (eventName)
    for el in @
      callbacks = $.data(el, 'eventCallbacks') or []
      if not events
        for handler in callbacks
          el.removeEventListener handler.eventName, handler.callback
        return
      if typeof events is 'function'
        for handler in callbacks
          if handler.callback is handler
            el.removeEventListener handler.eventName, handler.callback
      for event in events.split /\s+/
        split = event.split('.')
        namespace = split[1]
        event = split[0]

        for handler in callbacks
          eventMatch =  not event or handler.eventName is event
          namespaceMatch = not namespace or handler.namespace is namespace
          handlerMatch = not handler or handler.callback is handler
          selectorMatch = not selector or handler.selector is selector

          if namespaceMatch and handlerMatch and selectorMatch and eventMatch
            el.removeEventListener handler.eventName, handler.callback
    @

  # FIXME: doesn't add each
  closest: (selector, context) ->
    return @ if @is selector
    out = $()
    els = if context then [context] else @
    if els.length
      for el in els
        if @is selector, el
          out.add el
        else
          while el = el.parentNode
            if @is selector, el
              out.add el
              break
    out

  is: (selector, context) ->
    el = context or @[0]
    if not selector
      false
    else if typeof selector isnt 'string'
      if selector[0]
        return true if contains $, el for el in selector
      else
        el is selector
    else
      matchesSelector = el["#{$.vendorPrefix true }MatchesSelector"]
      if matchesSelector
        matchesSelector.call el, selector
      else
        # FIXME: Very inefficient. Used to be in el.parentNode context,
        # but that doesn't work for things like is('html body.foo div')
        contains document.querySelectorAll(selector), el

  parent: (selector) ->
    $parent = null
    subject = @[0]
    if subject and selector
      while subject = subject.parentNode
        return $ subject if @is selector, subject
    else
      $ subject and subject.parentNode

  parents: (selector) ->
    $parents = $()
    subject = @[0]
    if subject
      while subject = subject.parent
        if not selector or @is selector, subject
          $parents.add subject
    $parents

  trigger: (event, data) ->
    event = $.Event event if $.isString(event) or $.isPlainObject(event)
    # FIXME: should be able to trigger a splat of args? or maybe no
    event.data = data

    for el in @
      if el.dispatchEvent
        el.dispatchEvent $.Event(event).originalEvent
      else if document.createEventObject
        el.fireEvent 'on#{event.type}', $.Event(event).originalEvent
    @

  children: (selector) ->
    if not selector
      $ @[0].children
    else
      $children = $()
      for child in @[0].children
        if @is selector, child
          $children.add(child)
      $children

  _attr: (name, value) ->
    if not value?
      @[0] and @[0].getAttribute name
    else
      for el in @
        continue if not el
        if value then el.setAttribute name, value
        else el.removeAttribute name
      @

  attr: (name, value) ->
    unless typeof name is 'object' then @_attr name, value
    else @_attr key, value for key, value of name

  _css: (name, value) ->
    # FIXME: use el.currentStyle for ie < 9
    if not value?
      camelName = $.camelize name
      el = @[0]
      return if not el
      style = el.style[camelName]
      return style if style
      if getComputedStyle
        getComputedStyle(el, '').getPropertyValue name
      else if el.currentStyle
        el.currentStyle[camelName]
    else
      for el in @
        isNumber = typeof value is 'number'
        isPosition = ///width|height|top|bottom|left|border|padding|
          margin|\right|size///i.test(name)
        value += 'px' if isNumber and isPosition
        el.style[$.camelize name] = value

  css: (name, value) ->
    if typeof name is 'object' then @_css key, value for key, value of name
    else @_css name, value
    @

  filter: (selector) ->
    res = $()
    for el in @
      if typeof selector is 'function' then res.add el if selector el
      else res.add el if @is selector, el
    res

  data: (name, value) ->
    if value
      for el in @
        $.data el, name, value
    else
      el = @[0]
      if not el undefined else $.data el, name

  on:  (event, args...) ->
    fn = args.pop()
    if typeof args[0] is 'string'
      selector = args.shift()
    data = args[0]

    addCallback = (event, cb, args = []) =>
      if not selector
        callback = (e) =>
          cb.apply @, [e].concat args
      else
        callback = (e) =>
          $target = @closest selector, e.target
          if $target.length
            e.liveFire = true
            e.currentTarget = $target[0]
            cb.apply @, [e].concat args

      callbackProxy = (e) =>
        res = callback $.Event e
        if res is false
          e.stopPropagation()
          e.preventDefault()
        res

      addEvent = (el) =>
        return if not el
        split = event.split '.'
        eventName = split[0]
        namespace = split[1]

        # FIXME: move to $.data
        callbacks = $.data el, 'eventCallbacks'
        if not callbacks
          callbacks = []
          $.data 'eventCallbacks', callbacks

        callbacks.push
          selector: selector
          callback: callback
          namespace: namespace
          eventName: eventName

        if el.addEventListener
          el.addEventListener eventName, callbackProxy, false

      addEvent el for el in @

    if typeof event is 'string'
      for evt in event.split /\s+/
        addCallback evt, fn
    else
      for key, value of event
        for evt in key.split /\s+/
          addCallback evt, value
    @

  # FIXME: support offset(coordinates)
  offset: ->
    el = @[0]
    if el instanceof Element
      rect = el.getBoundingClientRect()

      left: rect.left + window.pageXOffset,
      top: rect.top + window.pageYOffset
      width: rect.width
      height: rect.height

    else
      width: el and ( el.width or el.innerWidth ) or 0
      height: el and ( el.height or el.innerHeight ) or 0
      top: 0
      left: 0

  #  FIXME: Add zepto style for transforms
  #  $().animate
  #    rotateZ: '45deg'
  animate: (properties, duration = $.fx.duration, easing = $.fx.duration, cb) ->
    @delayTime += duration
    deferred = @animationDeferred = $.Deferred()
    props = ''
    props += " #{$.dasherize name}" for name of properties

    animate = =>
      for el in @
        $el = $ el
        prefix = $.vendorPrefix()
        css = {}
        propNames = ['property', 'timing-function', 'duration']
        propVals = [props, easing, "#{duration}ms"]
        for propName, index in propNames
          css["#{prefix}#{propName}"] = propVals[index]

        # Support for { translateZ: '10px' }, etc ala zepto
        css["#{prefix}transition"] ?= ''
        for value, key of properties
          css["#{prefix}transition"] += ' #{key}(#{value})' if \
            ///^((translate|rotate|scale)(X|Y|Z|3d)?|matrix(3d)?
              |perspective|skew(X|Y)?)$///i.test(key)

        $el.css $.extend css, properties
        deferred.then =>
          if @animationDeferred is deferred
            for prop in propNames
              delete el.style["#{prefix}#{prop}"]

      deferred.then cb if cb
      setTimeout deferred.resolve.bind(deferred), duration

    if @delayTime then setTimeout animate, @delayTime else animate()
    @

  delayTime: 0

  delay: (time) ->
    @delayTime += time
    @delayTime = 0 if @delayTime < 0
    setTimeout ( => @delay -time ), time if time > 0
    @


# Prototype Setup - - - - - - - - - - - - - - - - - - - - -

$.fn.init:: = $.fn
$.fn.extend = (obj) -> $.extend $.fn, obj


# Helpers - - - - - - - - - - - - - - - - - - - - - - - - -

stringOrNodeObjects = ['[object Text]', '[object String]', '[object Comment]']

contains = (arr, item) ->
  arr = [].slice.call arr if not $.isArray arr
  arr.indexOf(item) isnt -1

isStringLike = (value) ->
  contains stringOrNodeObjects, ({}).toString.call value

_extend = (target, source, deep) ->
  for key, value of source
    valIsPlainObj = $.isPlainObject value
    if deep and ( valIsPlainObj or $.isArray value )
      target[key] = {} if valIsPlainObj and not $.isPlainObject target[key]
      target[key] = [] if $.isArray(value) and not $.isArray target[key]
      _extend target[key], value, deep
    else
      target[key] = value if value isnt undefined


# Global methods - - - - - - - - - - - - - - - - - - - - - -

# unique id counter
uid = 0

$.isPlainObject = (obj) -> "#{obj}" is '[object Object]'
$.capitalize = (string) -> string[0].toUpperCase() + string.substring(1)
$.dasherize = (string) -> string.replace /([a-z])([A-Z])/, '$1-$2'
$.uniqueId = (namespace) -> if namespace then "#{namespace}#{uid++}" else uid++
$.noConflict = -> window.$ = original$ ; $
$.isArray = (obj) -> Array.isArray obj
$.isStringLike = isStringLike

$.data = (element, key, value) ->
  return if not element
  unless value
    expandoData[element[expando]]
  else
    element[expando] ?= $.uniqueId()
    id = element[expando]
    expandoData[id] ?= {}
    expandoData[id][key] = value

$.contains = (parent, contained) ->
  parent isnt contained and parent.contains contained

$.extend = (target, args...) ->
  if typeof target is "boolean"
    deep = target
    target = args.shift()
  _extend target, arg, deep for arg in args
  target

$.compact = (array = [], newArr = []) ->
  ( newArr.push item if item ) for item in array
  newArr

$.camelize = (string) ->
  string.replace /[ _\-]+(.)?/g, (match, character) ->
    character.toUpperCase if character else ''

$.alias = (context, aliasArrays...) ->
  if aliasArrays[0] not instanceof Array
    aliasArrays = ( [key].concat value for key, value of aliasArrays[0] )
  for aliasArray in aliasArrays
    original = context[aliasArray[0]]
    for alias, index in aliasArray
      context[alias] ?= original

$.unique = (arr) ->
  out = []
  for item in arr
    out.push item if out.indexOf(item) is -1
  out

$.flatten = (input, output = []) ->
  for value in input
    if value
      if value.length? and not isStringLike value
        $.flatten value, output
      else
        output.push value
  output

$.each = (arr, fn) -> fn.call arr, index, el for el, index in arr


# Constructed methods - - - - - - - - - - - - - - - - - - -

for item in [ 'Object', 'Element' ]
  do (item) ->
    $["is#{item}"] = (obj) -> obj instanceof window[item]

for item in ['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp']
  do (item) ->
    $["is#{item}"] = (obj) -> ({}).toString.call(obj) is "[object #{item}]"

for method in ['next', 'prev']
  do (method) ->
    $.fn[method] = (selector) ->
      res = $()
      for el in @
        name = if method is 'next' then 'next' else 'previous'
        newEl = el["#{name}ElementSibling"]
        if selector? then res.add newEl if selector and @is newEl, selector
        else if newEl then res.add newEl
      res

for method in ['height', 'width']
  do (method) ->
    $.fn[method] = (val) ->
      if not val
        return @[0] and $(@[0]).offset()[method]
      else
        for el in @
          el.style[method] = if typeof val is 'number' then  "#{val}px" else val

for direction in ['top', 'left']
  do (direction) ->
    name = "scroll#{$.capitalize direction}"
    $.fn[name] = (val) ->
      unless val? then @[0] and @[0][name]
      else el[name] = val for el in @
      @

for action, index in ['after', 'prepend', 'before', 'append']
  do (action, index) ->
    inside = contains ['prepend', 'append'], action

    $.fn[action] = (nodes...) ->
      nodes = $ $.compact nodes
      cloneNode = @length > 1
      return @ unless nodes.length

      for target in @
        # FIXME: make sure better compacting self
        continue if not target
        parent = if inside then target else target.parentNode
        switch action
          when 'after'   then target = target.nextSibling
          when 'prepend' then target = target.firstChild
          when 'append'  then target = null

        for node in nodes
          continue if not node
          if cloneNode
            node = node.cloneNode(true)
          else if not parent
            return $(node).remove()

          parent.insertBefore node, target
      @

    if inside then altMethodName = "#{action}To"
    else altMethodName = "insert#{if index then 'Before' else 'After'}"

    $.fn[altMethodName] = (html) -> $(html)[action] @ ; @


# Global animation defaults - - - - - - - - - - - - - - - -

$.fx =
  off: false
  duration: 300
  easing: 'linear'


# DOM ready - - - - - - - - - - - - - - - - - - - - - - - -

DOMReadyCallbacks = []
DOMIsReady = contains /complete|loaded|interactive/.test document.readyState

DOMIsNowReady = ->
  DOMIsReady = true
  callback() for callback in DOMReadyCallbacks

if window.addEventListener
  document.addEventListener "DOMContentLoaded", DOMIsNowReady, false
else
  setTimeout DOMIsNowReady, 0

$.ready = $.fn.ready = (callback) ->
  if DOMIsReady then callback() else DOMReadyCallbacks.push callback


# Deferred - - - - - - - - - - - - - - - - - - - - - - - - -

$.Deferred = (options = {}) ->
  tuples = [
    [ 'resolve', 'done', 'resolved' ]
    [ 'reject', 'fail', 'rejected' ]
    [ 'notify', 'progress' ]
  ]

  promise =
    status: 'pending'
    state: -> @status
    then: (done, fail, progress) -> @.done(done).fail(fail).progress(progress)
    promise: (obj = {}) -> $.extend obj, @

  for tuple in tuples
    do (tuple) =>
      promise["#{tuple[0]}Callbacks"] = []

      promise["#{tuple[0]}With"] = (context, args...) ->
        @context = context if context
        @args = args if args
        callbacks = @["#{tuple[0]}Callbacks"]
        callbacks.concat @alwaysCallbacks if tuple[0] isnt 'notify'

        if @status is 'pending'
          callback.apply @context, @args for callback in callbacks
          @status = tuple[2] if tuple[2]
        @

      promise[ tuple[0] ] = (args...) ->
        @["#{tuple[0]}With"].apply @, [null].concat args

      promise[tuple[1]] = (args...) ->
        args = args[0] if args[0] instanceof Array
        callbacks = promise["#{tuple[0]}Callbacks"]
        if @status is tuple[2]
          for callback in callbacks
            callback.apply @context, @args if callback
        else
          callbacks.push.apply callbacks, $.compact args
        @

  promise

$.when = (defereds...) ->
  len = deferreds.length
  called = 0
  whenDeferred = $.Deferred()
  for deferred in deferreds
    deferred.fail -> whenDeferred.reject()
    deferred.then -> whenDeferred.resolve() if ++called >= len
  whenDeferred


# Event - - - - - - - - - - - - - - - - - - - - - - - - - -

# FIXME: use angular jqlite event modification instead?
class $.Event
  constructor: (type, props = {}) ->
    return type if type instanceof $.Event
    return new $.Event type, props if @ not instanceof $.Event

    unless typeof type is 'string'
      props = type
      type = props.type

    mouseEvts = ['click', 'mousedown', 'mouseup', 'mousemove']
    eventType = if contains mouseEvts, type then 'MouseEvents' else 'Events'

    # FIXME: add keyboard events?
    isEvent = props instanceof Event or props instanceof MouseEvent \
      or props instanceof KeyboardEvent

    if isEvent
      event = props
    else
      if document.createEvent
        event = document.createEvent eventType
      else if document.createEventObject
        event = document.createEventObject()

      event.type ?= type
      bubbles = true

      for name, value of props
        if name is "bubbles" then bubbles = !!value
        else event[name] = value

    fixEvent event
    event.isDefaultPrevented = -> @defaultPrevented

    # if not isEvent
    event.initEvent type, bubbles, true, null

    ignoreProps = /^([A-Z]|layer[XY]$)/
    eventMethods =
      preventDefault: "isDefaultPrevented"
      stopImmediatePropagation: "isImmediatePropagationStopped"
      stopPropagation: "isPropagationStopped"

    eventProxy = originalEvent: event

    for key of event
      if not ignoreProps.test(key) and event[key] isnt undefined
        eventProxy[key] ?= event[key]
    for name, predicate in eventMethods
      do (name, predicate) ->
        eventProxy[name] = ->
          @[predicate] = -> true
          e[name].apply event, arguments

        eventProxy[predicate] = -> false

    return eventProxy

fixEvent = (event) ->
  event.originalEvent = event
  originalPreventDefault = event.preventDefault
  event.target ?= event.srcElement
  if not event.preventDefault or 'defaultPrevented' not of event
    event.defaultPrevented = false
    event.preventDefault = ->
      @defaultPrevented = true
      @returnValue = false
      originalPreventDefault.call @ if originalPreventDefault
  event

eventHandlers = {}
_$id = 1

# Detect Browser - - - - - - - - - - - - - - - - - - - - - -

ua = navigator.userAgent
$.webkit  = !!ua.match /WebKit\/([\d.]+)/
$.opera   = !!ua.match /\ OPR\/(\d+)/
$.chrome  = !!( not $.opera and ua.match /Chrome\/([\d.]+)/ )
$.firefox = !!ua.match /Firefox\/([\d.]+)/
$.ie      = !!ua.match /MSIE ([0-9]{1,}[\.0-9]{0,})/i
$.touch   = 'ontouchstart' of window

$.vendorPrefix = (forJS) ->
  prefix = '-webkit-' if $.webkit
  prefix = '-moz-'    if $.firefox
  prefix = '-ms-'     if $.ie
  prefix = '-o-'      if $.opera and not $.webkit
  prefix ?= ''

  if forJS then prefix.replace /-/g, '' else prefix


# Ajax - - - - - - - - - - - - - - - - - - - - - - - - - - -

# FIXME: user jquery ajaxSetup
$.ajaxSettings =
  type: 'GET'
  context: null
  global: true
  async: true
  accepts:
    script: 'text/javascript, application/javascript'
    json: 'application/json'
    xml: 'application/xml, text/xml'
    html: 'text/html'
    text: 'text/plain'
  crossDomain: false
  timeout: 0
  processData: true
  cache: true
  beforeSend: ->
  success: ->
  error: ->
  complete: ->
  xhr: (o) ->
    if o.crossDomain and o.async and window.XDomainRequest
      new XDomainRequest
    else
      new XMLHttpRequest

$.ajaxSetup = (options) ->
  $.extend $.ajaxSettings, options

if 'withCredentials' not of new XMLHttpRequest()
  $.ajaxSettings.xhr = (o) ->

appendQuery = (url, query) -> "#{url}&#{query}".replace /[&?]{1,2}/, '?'

serializeData = (options) ->
  if options.processData and options.data and typeof options.data isnt "string"
    options.data = $.param(options.data, options.traditional)
  if options.data and (!options.type or options.type.toUpperCase() is "GET")
    options.url = appendQuery(options.url, options.data)

mimeToDataType = (mime) ->
  mime =  mime and mime.split(";", 2)[0] or 'text'
  if      mime is 'text/html'                             then 'html'
  else if mime is 'appliction/json'                       then 'json'
  else if /^(?:text|application)\/javascript/i.test(mime) then 'script'
  else if /^(?:text|application)\/xml/i.test(mime)        then 'xml'
  else    mime

serialize = (params, obj, traditional, scope) ->
  type = null
  array = $.isArray(obj)
  for key, value of obj
    type = $.type(value)
    if scope
      key = if traditional then scope else "#{scrope}[#{unless array then key}]"

    if not scope and array
      params.add value.name, value.value
    else if type is "array" or (not traditional and type is "object")
      serialize params, value, traditional, key
    else
      params.add key, value

$.param = (obj, traditional) ->
  params = []
  params.add = (k, v) ->
    @push escape(k) + "=" + escape(v)

  serialize params, obj, traditional
  params.join("&").replace /%20/g, "+"


$.ajaxJSONP = (options) ->
  return $.ajaxoptions unless 'type' of options
  callbackName = 'jsonp' + $.uniqueId 'jsonP'
  script = document.createElement('script')
  deferred = $.Deferred()

  cleanup = ->
    clearTimeout abortTimeout
    $(script).remove()
    delete window[callbackName]

  abort = (type) ->
    cleanup()
    window[callbackName] = empty  if not type or type is 'timeout'
    # FIXME: ajaxFail is currently not accessible here
    deferred.fail()
    ajaxError null, type or 'abort', xhr, options

  xhr = abort: abort
  abortTimeout = null
  if ajaxBeforeSend(xhr, options) is false
    abort 'abort'
    return false

  window[callbackName] = (data) ->
    cleanup()
    # FIXME: ajaxSuccess is currently not accessible here
    deferred.done()
    ajaxSuccess data, xhr, options

  script.onerror = ->
    abort 'error'

  script.src = options.url.replace /\=\?/, "=#{callbackName}"
  $('head').append script
  if options.timeout > 0
    abortTimeout = setTimeout(->
      abort 'timeout'
    , options.timeout)

  deferred


# FIXME: add deferred
$.ajax = (options) ->
  o = $.extend {}, options
  for key of $.ajaxSettings
    o[key] = $.ajaxSettings[key] if o[key] is undefined
  deferred = $.Deferred()

  triggerGlobal = (eventName, data = [ xhr, o ]) ->
    event = $.Event eventName
    event.data = data
    $(document).trigger(event)
    return !event.defaultPrevented

  ajaxComplete = ->
    o.complete.call o.context, xhr, xhr.status, o
    triggerGlobal 'ajaxComplete'

  ajaxError = (error, type) ->
    deferred.fail()
    triggerGlobal 'ajaxStop', [ xhr, xhr.status, error]
    o.error.call o.context, xhr, type, error
    ajaxComplete()

  ajaxSuccess = (result) ->
    deferred.done()
    o.success.call o.context, result, xhr.status, xhr
    triggerGlobal 'ajaxStop'
    ajaxComplete()

  ajaxBeforeSend = ->
    return false if triggerGlobal('ajaxBeforeSend') is false
    triggerGlobal 'ajaxSend'

  triggerGlobal 'ajaxStart'

  hostRegex = /^([\w-]+:)?\/\/([^\/]+)/
  protocolRegex = /^([\w-]+:)\/\//
  if not o.crossDomain
    o.crossDomain = hostRegex.test(o.url) and RegExp.$2 isnt location.host

  o.url = location.toString() unless o.url
  serializeData o
  o.url = appendQuery o.url, '_=' + Date.now() if o.cache is false

  if o.dataType is 'jsonp' or /\=\?/.test o.url
    o.url = appendQuery(o.url, 'callback=?')  unless hasPlaceholder
    return $.ajaxJSONP o

  mime = o.accepts[o.dataType]
  baseHeaders = {}
  protocol = if protocolRegex.test o.url then RegExp.$1 else location.protocol
  abortTimeout = null
  baseHeaders['X-Requested-With'] = 'XMLHttpRequest' unless o.crossDomain

  xhr = o.xhr(o)
  if mime
    baseHeaders['Accept'] = mime
    mime = mime.split(',', 2)[0] if mime.indexOf(',') > -1
    xhr.overrideMimeType and xhr.overrideMimeType mime

  type = o.type.toUpperCase()
  if o.contentType or o.contentType isnt false and o.data and type isnt 'GET'
    baseHeaders['Content-Type'] = \
      o.contentType or 'application/x-www-form-urlencoded'

  o.headers = $.extend baseHeaders, o.headers
  xdr = xhr not instanceof XMLHttpRequest
  readyStateChangeMethod = if xdr then 'onload' else 'onreadystatechange'

  if xdr
    xhr.onerror = ->
      xhr.status ?= 500
      ajaxError null, 'error', xdr.responseText

  xhr[readyStateChangeMethod] = ->
    if xdr or xhr.readyState is 4
      xhr[readyStateChangeMethod] = ->
      clearTimeout abortTimeout
      error = false
      s = if xdr then 200 else xhr.status

      if (s >= 200 and s < 300) or s is 304 or (s is 0 and protocol is 'file:')
        o.dataType ?= mimeToDataType xhr.getResponseHeader 'content-type'
        result = xhr.responseText
        try
          switch o.dataType.toLowerCase()
            when 'script' then eval result
            when 'xml'    then result = xhr.responseXML
            when 'json'   then result = JSON.parse result
        catch e
          error = e

        if error
          ajaxError error, 'parsererror'
        else
          ajaxSuccess(result)
      else
        deferred.fail
        ajaxError null, if xhr.status then 'error' else 'abort'

  xhr.open o.type, o.url, true

  if not xdr
    xhr.setRequestHeader name, value for name, value of o.headers

  if ajaxBeforeSend() is false
    # Should this also call ajaxError() ?
    xhr.abort()
    return false

  if o.timeout > 0
    abortTimeout = setTimeout(->
      xhr[readyStateChangeMethod] = ->
      xhr.abort()
      ajaxError null, 'timeout'
    , o.timeout)

  # avoid sending empty string (#319)
  xhr.send o.data or null
  deferred

# TODO
$.get = (url, data, success, dataType) ->
$.getJSON = (url, data, success, dataType) ->
$.post = (url, data, success, dataType) ->


# Method Aliases - - - - - - - - - - - - - - - - - - - - - -

# Add a set of array methods
for method in ['forEach', 'reduce', 'reduceRight', 'sort', 'slice'
  'every', 'some', 'join', 'pop', 'push', 'reverse', 'shift', 'splice',
  'unshift', 'concat', 'indexOf', 'lastIndexOf' ]
  $.fn[method] = [][method]

events = 'blur focus focusin focusout load resize scroll unload click
 dblclick mousedown mouseup mousemove mouseover mouseout mouseenter mouseleave
 change select submit keydown keypress keyup error contextmenu
 touchstart touchend touchmove touchleave touchcancel'.split(/\s+/)

for event in events
  do (event) ->
    $.fn[event] = (callback) ->
      if callback then @on event, callback else @trigger event

$.alias(
  $::,
  ['off', 'unbind', 'undelegate', 'die'],
  ['on', 'bind', 'delegate', 'live']
)


# Debug - - - - - - - - - - - - - - - - - - - - - - - - - -

$.support = {}
# TODO
$.event =
  add: ->
  remove: ->

# For debugging
# window.jQuery = $

# Export - - - - - - - - - - - - - - - - - - - - - - - - -

$.VERSION = '0.0.5'
window.$ = $
window.Dollar = $
