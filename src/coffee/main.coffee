###
  TODO:
    - Logic for where to position tags
      -  Add different classes for different arrow positions
    - Look for data in window or ajax if not there via pict id on image

  Pict({ el: el })
  Tag({ el: el })
###


# namespace
ns = 'pict'
tagName = unless $.ie then "#{ns}-el" else 'div'

touch = 'ontouchstart' of window


# Track - - - - - - - - - - - - - - - - - - - - - - - - - -

class Tracker extends Base
  constructor: ->
    super

  @track: ->
    # TODO: track metrics through our backend


# Pict Class - - - - - - - - - - - - - - - - - - - - - - -

class Pict extends Base.View
  constructor: (@options, @img) ->
    super @options

    if @img not instanceof $
      @img = $ @img

    @insertContainer()
    @insertTags()
    @flashTags()

  hovered: false
  tags: []

  tagName = "#{tagName}"
  className: "#{ns}-container"

  activateTag: (activeTag) ->
    for tag in @tags
      if tag isnt activeTag and tag.active
        tag.hide()

  insertContainer: ->
    @$el.addClass if touch then "#{ns}-touch" else "#{ns}-no-touch"
    @$el.insertBefore(@img).append @img

  events:
    mouseout: -> @$el.removeClass "#{ns}-show-dots"
    touchend: -> @activateTag()
    mouseover: ->
      @hovered = true
      @$el.addClass "#{ns}-show-dots"

  insertTags: ->
    for product in @options.products
      tag = new Tag product, @options, @
      @insertView tag

  flashTags: ->
    delay 1000, =>
      @$el.addClass "#{ns}-show-dots"
      delay 1000, =>
        if not @hovered
          @$el.removeClass "#{ns}-show-dots"


# Tag Class - - - - - - - - - - - - - - - - - - - - - - - -

class Tag extends Base.View
  constructor: (@product, @options, @parent) ->
    super

    @hotspot = $ "
        <#{tagName} class='#{ns}-hotspot'
          style='top: #{@product.top}%; left: #{@product.left}%'>
        </#{tagName}>
      "

    @tag = $ "
        <#{tagName} class='#{ns}-tag'
          style='top: #{@product.top}%; left: #{@product.left}%'>
        </#{tagName}>
      "

    @render()

  outOfHotspot: true
  outOfTag: true
  visible: false
  tagName: "#{tagName}"

  render: ->
    @insertHotspot()

  insertHotspot: ->
    @$el.append @hotspot

  remove: ->
    @hotspot.remove()
    @tag.remove()

  events: ->
    initEvent = if touch then 'touchend' else 'mouseover'

    res = {}
    res["mouseout .#{ns}-hotspot"] = (e) =>
      @outOfHotspot = true
      @hideIfMouseHasLeftFullTag()

    res["mouseout .#{ns}-tag"] = (e) =>
      @outOfTag = true
      @hideIfMouseHasLeftFullTag()

    res["#{initEvent} .#{ns}-hotspot"] = (e) =>
      if touch and @active
        @hide()
      else
        @outOfHotspot = false
        @showIfMouseIsWithinFullTag()

    res["#{initEvent} .#{ns}-tag"] = (e) =>
      @outOfTag = false

    res

  hide: ->
    @active = false
    @hotspot.removeClass "#{ns}-active"
    @tag.removeClass "#{ns}-active"

    delay 200, =>
      if not @active
        @tag.detach()

  show: ->
    @active = true
    @$el.append @tag
    @hotspot.addClass "#{ns}-active"
    @parent.activateTag @

    delay 1, =>
      @tag.addClass "#{ns}-active"

  hideIfMouseHasLeftFullTag: ->
    delay 10, =>
      if @outOfTag and @outOfHotspot
        @hide()

  showIfMouseIsWithinFullTag: ->
    delay 10, =>
      if not @active
        @show()


# Jquery fn - - - - - - - - - - - - - - - - - - - - - - - -

$.fn.pict = (options) ->
  for el in this
    new Pict options, el


# Init - - - - - - - - - - - - - - - - - - - - - - - - - - -

# For ie < 9 to allow a custom tag
document.createElement "#{tagName}"

$ ->

  $(".#{ns}-image").pict
    products: [
      top: 35
      left: 20
    ,
      top: 40
      left: 45
    ,
      top: 60
      left: 35
    ,
      top: 80
      left: 45
    ,
      top: 95
      left: 95
    ]


# Helpers - - - - - - - - - - - - - - - - - - - - - - - - -

delay = (time, fn) ->
  setTimeout fn, time
