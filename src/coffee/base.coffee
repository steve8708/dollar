###
  FIXME: may need to run super before constructors, instead of after
    e.g. so initializations have run and can access things like @data if on
    initializing calling @set()
  TODO: return self everywhere where not returning something else
  TODO: router ?
     make singleton - just one per page
     with query string args too
  TODO: sync
  TODO: singleton, collection
  TODO: support nested get, set, on, off, listenTo, stopListening
    set foo.bar, get foo.bar, on change:foo.bar.baz[0]
  TODO: model blacklist
  TODO: add api for special events (e.g. with filters, etc)
     click: 'foo # defer'
     click: 'set:foo:"bar"'

  Allow special events (and unbind them on undelegate / remove / destroy)
    model: { 'change:foo': 'bar' }
    window: { 'scroll': 'onScroll' }

  TODO: setElement

  once
  listenonce

  FIXME: only trigger 'change' on set if prop has changed

  TODO: once(), listenToOnce()
  Universal cid in order of when object created
###

cid = 0

# TODO: keys, values, paris, invert, pick, omit (underscore methods)

class Base
  constructor: (args...) ->
    @name = (@constructor.name or '').toLowerCase()
    @data = {}
    @callbacks = []
    @listenerContexts = []
    @cid = cid++

    @initialize.apply @, args if @initialize
    @trigger.apply @, ['initialize'].concat args

  get:   (name)         -> @data[name]
  has:   (attr)         -> !! @get attr
  unset: (key, options) -> @set key, undefined, options
  toJSON:               -> $.extend {}, @data

  set: (name, val, options = {}) ->
    return @ if not name

    @data[name] = val
    if not options.silent
      @trigger "change:#{name}"
    @

  getState: ->
  setState: ->
  getDeep: ->
  setDeep: ->
  onDeep: ->
  offDeep: ->

  off: (event, ctx) ->
    if not ctx and typeof event isnt 'string'
      ctx = event
      event = null

    if not event and not ctx
      @callbacks = []
    else
      newCallbacks = []
      @callbacks.every (callback) =>
        if callback.event isnt event and callback.context isnt context
          newCallbacks.push callback

      @callbacks = newCallbacks
    @

  on: (event, callback, context, ctx) ->
    event.split(/\s+/).every (evt) =>
      @callbacks.push
        event: evt
        callback: callback
        context: context
        ctx: ctx
      @

  clear: (options) ->
    @unset key, options for key, value of @data
    @

  trigger: (event, args...) ->
    @callbacks.every (callback) =>
      if callback.event is event
        callback.callback.apply callback.context or @, args

    if @collection instanceof Base
      @collection.apply @collection, [event].concat args

    isChildEvent = event.indexOf('child:') is 0
    isBroadcastEvent = event.indexOf('broadcast:') is 0

    if not isBroadcastEvent and @parent instanceof Base
      eventName = if isChildEvent then event else "child:#{event}"
      @parent.trigger.apply @parent, [eventName].concat args

    if not isChildEvent and @children instanceof Base
      isChildEvent =
      eventName = if isBroadcastEvent then event else "broadcast:#{event}"
      for child in @children
        @child.trigger.apply @child, [eventName].concat args
    @

  computeProperty: (name, args...) ->
    switch typeOf name
      when "object" then obj = args[0]
      when "array"  then obj = triggers: args[0], fn: args[1]
      when "string" then obj = fn: args.pop(), triggers: args

    # FIXME: don't parse all items on every update
    # should save contexts and property getter strings
    callback = =>
      values = obj.triggers.map (trigger) =>
        @_parseObjectGetter(trigger.replace("[*]", ""), @).value

      result = obj.fn.apply @, values
      @set name, result

    # FIXME: remove this duplicate
    for trigger in obj.triggers
      obj = @_parseObjectGetter trigger, @
      @listenTo obj.moduleContext, "change:#{obj.propNameString}", callback
      @on "change:#{trigger}", callback
    callback()

  listenTo: (context, event, callback) ->
    context.on event, callback, @, @
    @listenerContexts.push context
    @

  stopListening: (event) ->
    for context in @listenerContexts
      if event then context.off event, @
      else context.off @
    @


# FIXME: this isn't working, it is creating a new dude
Base.extend = (child, classOptions) ->
  _extends child, @
  $.extend child, classOptions


class App extends Base
  constructor: ->
    super


class Singleton extends Base
  constructor: ->
    super


# TODO: add, pop, remove, shift, unshift, slice, filter, etc
# Allow collections of views
# Bubble 'change' events from models
# Change:
class Collection extends Base
  constructor: ->
    super
    []

  add: -> @pop.apply @, arguments
  each: -> @forEach.apply @, arguments

  get: (id) ->
    for item in @
      if item.get
        return item if item.get(item.idAttribute or 'id') is id
      else if item.id is id
        return item

  at: (index) -> @[index]
  toJSON: -> [].slice.call @

  set: (models, options) ->
    []::push.apply @, models
    if not options or not options.silent
      # FIXME: this is inconsistent with other events
      # having one model per 'add'
      #   trigger muleiple 'adds' instead?
      @trigger 'add', models, options
    @

  reset: (models, options) ->
    if not options or not options.silent
      @trigger 'reset', options
    @length = 0
    @set models, $.extend {}, options, silent: true
    @


for method in ['push', 'unshift']
  Collection::[method] = (args...) ->
    for item in args
      if @model and item not instanceof @model
        item = new @model item
      item.collection = @

    [][method].apply @, args
    @trigger.apply @, ['add'].concat args
    @

for method in ['pop', 'shift']
  Collection::[method] = (args...) ->
    [][method].apply @, args

    for item in args
      delete item.collection

    @trigger.apply @, ['remove'].concat args
    @

# FIXME: maybe add _ methods instead
for method in ['forEach', 'map', 'reduce', 'reduceRight', 'sort', 'filter',
  'every', 'some', 'join', 'pop', 'push', 'reverse', 'shift', 'splice', 'slice'
  'unshift', 'concat', 'indexOf', 'lastIndexOf' ]
  Collection::[method] = [][method]

class View extends Base
  constructor: (@options, @data) ->
    super

    @children = new Collection parent: this

    @el ?= @options.el or @$el and @$el[0] or options.$el and options.$el[0] \
       or $("<#{@tagName}></#{@tagName}>")[0]

    @$el = $ @el
    @set @data

    if @className
      @$el.addClass @className

    if @attributes
      @$el.attr _.result @, 'attributes'

    @delegateEvents()

  tagName: 'div'

  setElement: (element, delegate) ->
    @undelegateEvents() if @$el
    @$el = if element instanceof $ then element else $ element
    @el = @$el[0]
    @delegateEvents() if delegate isnt false
    @

  compileTemplate: (template) ->
    template ?= @template


  attributes: ->
    'data-view': @name

  subView: (view) ->
    if view not instanceof View
      view = new view(args)

    view.parent = @

    @children.add view

  insertView: (selector, view) ->
    if not view
      view = selector
      selector = null

    @subView view

    if selector
      @.$(selector).append view.$el
    else
      @$el.append view.$el
    @

  $: (args...) ->
    @$el.find.apply @el, args

  delegateEvents: (events) ->
    # FIXME: use _.range for this
    events ?= if typeof @events is 'function' then @events() else @events

    for event, callback of events
      eventSplit = event.split(/\s+/)
      eventName = eventSplit[0]
      eventSelector = eventSplit.slice(1).join(' ')
      method = (@[callback] or callback).bind @
      @$el.on "#{eventName}.delegateEvent#{@cid}", eventSelector, method
    @

  remove: ->
    @$el.remove()
    @undelegateEvents()
    @$el.off()
    # TODO: also $el.removeData()

    child.destroy() for child in @children
    @

  # TODO
  undelegateEvents: ->
    # Looping through and calling 'off' may not work because callbacks get
    # modified when adding .bind to them
    @$el.off(".delegateEvent#{@cid}")
    @


# TODO: defaults, etc
class Model extends Base
  constructor: ->
    super


# FIXME: support :var and @splat
class Router extends Base
  constructor: (options={}) ->
    if options.pushState is false
      window.on 'hashchange', @checkUrl
    else
      window.on 'popstate', @checkUrl

    super

  checkUrl: (e) ->
    # Get fragment
    # Pass in variables
    @

  go: (args...) ->
    @navigate.apply @, args

  navigate: (url) ->
    window.history.pushState({}, document.title, url)
    @


# Helpers - - - - - - - - - - - - - - - - - - - - - - - - - -

_extends = (child, parent) ->
  ctor = ->
    @constructor = child

  for key of parent
    child[key] = parent[key] if parent.hasOwnProperty(key)

  ctor:: = parent::
  child:: = new ctor()
  child.__super__ = parent::
  child

typeOf = (subject) ->
  return ({}).toString.call(subject).match(/\s([a-z|A-Z]+)/)[1].toLowerCase()


# Export - - - - - - - - - - - - - - - - - - - - - - - - -

window.Base = Base
Base.Model = Model
Base.View = View
Base.Collection = Collection
Base.Router = Router
