###
  Put utilities = _.isfunction, etc in _ or $?

  TODO: cloneDeep
  TODO: 'intuitive chaining' (ala lodash) - certain methods return
    Line again
  TODO: chain, value
  TODO: camelize, etc

  TODO: _.merge (deep extend)
    other lodash additions
###

# Class - - - - - - - - - - - - - - - - - - - - - - - - - -

class Underline
  constructor: (arg) ->
    if @ not instanceof _
      return new _(arg)
    @_wrapped = arg

  chain: -> @_chain = true
  value: -> @_wrapped

_ = Underline

# Prototype - - - - - - - - - - - - - - - - - - - - - - - -

proto =
  # Collections - - - - - - - - - - - - - - - - - - - - - -
  find: (list, iterator, context) ->
    if typeof iterator isnt 'function'
      _.findWhere.apply @, arguments
    else
      for item in list
        return item if iterator.call context, item

  where: ->
  findWhere: ->
  size:     (obj) -> _.keys(obj).length
  chain:    (obj) -> _(obj).chain()
  toArray:  (obj) -> [].slice.call obj
  contains: (array, item) -> _.indexOf(array, item) isnt -1
  merge:    (objects...)  -> _.extend.apply _, [true].concat objects

  keys: Object.keys


  extend: (target, args...) ->
    extend = (target, source, deep) ->
      for key, value of source
        valIsPlainObj = _.isPlainObject value
        if deep and ( valIsPlainObj or _.isArray value )
          target[key] = {} if valIsPlainObj and not _.isPlainObject target[key]
          target[key] = [] if _.isArray(value) and not _.isArray target[key]
          extend target[key], value, deep
        else
          target[key] = value if value isnt undefined

    if typeof target is "boolean"
      deep = target
      target = args.shift()
    extend target, arg, deep for arg in args
    target

  # Arrays - - - - - - - - - - - - - - - - - - - - - - - - -

  first: (array, n) -> array and if n then array.splice(n) else array[0]

  last: (array, n) ->
    return if not array
    len = array.length
    if n then array.slice len - n, len else array[0 - 1]

  flatten: (input, shallow, output = []) ->
    if shallow and _.every input, _.isArray
      return concat.apply output, input
    for value in input
      if _.isArray(value) or _.isArguments(value) or value instanceof $
        if shallow
          push.apply output, value
        else
          _.flatten value, shallow, output
      else
        output.push value
    output

  compact: (array = [], newArr = []) ->
    ( newArr.push item if item ) for item in array
    newArr


  # Objects - - - - - - - - - - - - - - - - - - - - - - - -

  isNaN:         (obj) -> isNaN(obj)
  isNull:        (obj) -> obj is null
  isEmpty:       (obj) -> _.size(obj) is 0
  isArray:       (obj) -> Array.isArray obj
  isFinite:      (obj) -> isFinite(obj) and not isNaN parseFloat obj
  isBoolean:     (obj) -> obj is true or obj is false
  isUndefined:   (obj) -> obj is undefined
  isPlainObject: (obj) -> "#{obj}" is '[object Object]'


  # Functions - - - - - - - - - - - - - - - - - - - - - - -

  bind: (fn, ctx, args...) -> fn.bind.apply ctx, args
  bindAll: (obj, names...) -> obj[key] = method.bind obj for method in names
  partial: (fn, args...)   -> -> fn.apply @, args.concat arguments
  delay:   (fn, wait, args...) -> setTimeout (fn.bind.apply @, args), wait
  wait:    (wait, fn, args...) -> _.delay.apply _, [fn, wait].concat args


  # String - - - - - - - - - - - - - - - - - - - - - - - - -

  capitalize: (string) -> string[0].toUpperCase() + string.substring(1)
  dasherize: (string) -> string.replace /([a-z])([A-Z])/, '$1-$2'

  camelize: (string) ->
    string.replace /[ _\-]+(.)?/g, (match, character) ->
      character.toUpperCase if character else ''

  trim: (string) -> string and string.trim()

  alias: (context, aliasArrays...) ->
    if aliasArrays[0] not instanceof Array
      aliasArrays = ( [key].concat value for key, value of aliasArrays[0] )
    for aliasArray in aliasArrays
      original = context[aliasArray[0]]
      for alias, index in aliasArray
        context[alias] ?= original

  # Utility - - - - - - - - - - - - - - - - - - - - - - - -

  uniqueId: (namespace) -> if namespace then "#{namespace}#{i++}" else i++
  random: (min, max) ->
    if not max
      max = min
      min = 0
    Math.floor Math.random() * (max - min + 1) + min

  mixin: (mixins) ->
    # TODO

  result: (obj, item) ->
    if _.isFunction obj[item] then obj[item]() else obj[item]


# UniqueId Counter - - - - - - - - - - - - - - - - - - - - -

i = 0

# Instance validators - - - - - - - - - - - - - - - - - - -

for item in [ 'Object', 'Element' ]
  do (item) ->
    proto["is#{item}"] = (obj) -> obj instanceof window[item]

for item in ['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp']
  do (item) ->
    proto["is#{item}"] = (obj) -> ({}).toString.call(obj) is "[object #{item}]"

# Native aliases - - - - - - - - - - - - - - - - - - - - - -

apply =
  Array: [
    'forEach', 'map', 'reduce', 'reduceRight', 'sort', 'filter', 'every'
    'some', 'join', 'pop', 'push', 'reverse', 'shift', 'splice', 'slice'
    'unshift', 'concat', 'indexOf', 'lastIndexOf'
  ]
  Function: ['bind']

for name, list of apply
  prototype = window[name].prototype
  for item in list
    do (item, prototype) ->
      proto[item] = (obj, args...) ->
        # FIXME: get rid of this and for 'foreach' make sure it has
        # a function as an argument
        try
          prototype[item].apply obj, args
        catch e
          console.log 'native method error', item, obj, args, e

proto.alias proto, ['forEach', 'each'], ['sort', 'sortBy']

chainable = [
  'after', 'assign', 'bind', 'bindAll', 'bindKey', 'chain', 'compact', 'zip'
  'compose', 'concat', 'countBy', 'createCallback', 'debounce', 'defaults'
  'defer', 'delay', 'difference', 'filter', 'flatten', 'forEach', 'forIn'
  'forOwn', 'functions', 'groupBy', 'initial', 'intersection', 'invert'
  'invoke', 'keys', 'map', 'max', 'memoize', 'merge', 'min', 'object'
  'omit', 'once', 'pairs', 'partial', 'partialRight', 'pick', 'pluck'
  'push', 'range', 'reject', 'rest', 'reverse', 'shuffle', 'slice', 'sort'
  'sortBy', 'splice', 'tap', 'throttle', 'times', 'toArray', 'transform'
  'union', 'uniq', 'unshift', 'unzip', 'values', 'where', 'without', 'wrap'
]

for key, value of proto
  do (key, value) ->
    _[key] = value
    _::[key] = (args...) ->
      @_wrapped = value.apply @, [ @_wrapped ].concat args
      if _.contains( chainable, key ) then @ else @_wrapped

window._ = _

# Debug - - - - - - - - - - - - - - - - - - - - - - - - - -

window.Underline = _