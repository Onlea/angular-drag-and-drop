###
# Draggable Directive Controller
###
DraggableController = ($log, $document, $compile, DragAndDrop) ->

  draggableEl = null # the element to drag
  vm = this # view model for the controller

  # object for storing the start state when dragging
  start =
    rect: {}
    event: null
    translate: {x:0, y:0}

  # object for storing the current state when dragging
  current =
    rect: {}
    droppables: []
    event: null
    translate: {x:0, y:0}

  original =
    rect: {}

  getBodyOffset = (elem) ->
    bodyRect = document.body.getBoundingClientRect()
    elemRect = elem[0].getBoundingClientRect()
    offset =
      top: elemRect.top - bodyRect.top
      left: elemRect.left - bodyRect.left

  ###*
  # gets the screen coordinates from a mouse or touch event
  ###
  createClone = ->
    cloneEl = $compile(angular.element("<div>"+draggableEl.html()+"</div>"))(vm)
    cloneEl.addClass "clone"
    cloneEl.addClass draggableEl.attr "class"
    # element is added to body
    offset = getBodyOffset draggableEl
    cloneEl.css
      position: "absolute"
      top: offset.top + "px"
      left: offset.left + "px"
    $document.find("body").append cloneEl
    # element should be appended as sibling
    draggableEl = cloneEl

  positionClone = ->


  ###*
  # gets the screen coordinates from a mouse or touch event
  ###
  getEventCoordinates = (e) ->
    if e.touches and e.touches.length is 1
      return [ e.touches[0].clientX, e.touches[0].clientY ]
    else
      return [ e.clientX, e.clientY ]

  ###*
  # gets the bounding DOMRect of an element
  # @param {jQlite Element} el - jquery (lite) wrapped element
  # @return {DOMRect} - screen boundary of element
  ###
  getElementRect = (el) -> el[0].getBoundingClientRect()

  ###*
  # sets the x / y translation of an element
  # @param {jQlite Element} el
  # @param {int} x - x translate pixels
  # @param {int} y - y translate pixels
  ###
  setElementTranslate = (el, x, y) ->
    el.css
      "transform": "translate(#{x}px, #{y}px)"
      "-webkit-transform": "translate(#{x}px, #{y}px)"
      "-ms-transform": "translate(#{x}px, #{y}px)"

  ###*
  # intitalizes the draggable
  ###
  vm.init = (element, options = {}) ->
    console.log "draggable init:", element, options, DragAndDrop
    draggableEl = element
    original.rect = getElementRect draggableEl
    current.rect = getElementRect draggableEl
    if options.id then vm.id = options.id else vm.id = DragAndDrop.uuid()
    if options.clone then createClone()


  ###*
  # handler for when the drag starts
  ###
  vm.start = (e) ->
    start.rect = getElementRect draggableEl
    start.event = e
    start.translate =
      x: current.translate.x
      y: current.translate.y
    start.coords = getEventCoordinates start.event
    vm.midPoint = [
      original.rect.left + start.translate.x + original.rect.width/2,
      original.rect.top + start.translate.y + original.rect.height/2
    ]

  ###*
  # handler for when moving the draggable
  ###
  vm.move = (e) ->
    current.coords = getEventCoordinates e
    current.event = e
    current.rect = getElementRect draggableEl
    current.translate.x =
      start.translate.x + (current.coords[0] - start.coords[0])
    current.translate.y =
      start.translate.y + (current.coords[1] - start.coords[1])
    vm.midPoint = [
      original.rect.left + current.translate.x + original.rect.width/2,
      original.rect.top + current.translate.y + original.rect.height/2
    ]
    setElementTranslate draggableEl, current.translate.x, current.translate.y

  ###*
  # handler for when moving the draggable
  ###
  vm.assignTo = (droppable) ->
    current.droppables.push droppable
    draggableEl.addClass "draggable-assigned"

  ###*
  # handler for when moving the draggable
  ###
  vm.removeFrom = (droppable) ->
    for item,i in current.droppables
      current.droppables.splice(i,1)
    unless current.droppables.length > 0
      draggableEl.removeClass "draggable-assigned"

  vm.getItems = -> return current.droppables

  ###*
  # checks if the draggable is assigned or not
  ###
  vm.isAssigned = ->
    if current.droppables.length > 0
      return true
    return false

  ###*
  # get the current dimensions of the draggable
  ###
  vm.getRect = ->
    return current.rect

  return vm

DraggableController.$inject = [ "$log", "$document", "$compile", "DragAndDrop" ]

draggableDirective = ($window, $document, $compile, DragAndDrop) ->

  linkFunction = (scope, element, attrs, draggable) ->

    pressEvents = "touchstart mousedown"
    moveEvents = "touchmove mousemove"
    releaseEvents = "touchend mouseup"

    processAttrs = ->
      options = {}
      if attrs.clone then options.clone = true
      return options

    ###*
    # handler for when the draggable is released
    # @param {Event} e - event when the item is released
    ###
    onRelease = (e) ->
      element.removeClass "draggable-active"
      DragAndDrop.trigger "drag-end", e
      DragAndDrop.setCurrentDraggable null
      $document.off moveEvents, onMove
      $document.off releaseEvents, onRelease

    ###*
    # handler for when the draggable is moved
    # @param {Event} e - event when the item is released
    ###
    onMove = (e) ->
      draggable.move e
      DragAndDrop.trigger "drag", e
      currentDrop = DragAndDrop.getCurrentDroppable()
      if currentDrop
        DragAndDrop.trigger "drag-in", e
      else
        DragAndDrop.trigger "drag-out", e

    ###*
    # handler for when the draggable is pressed
    # @param {Event} e - event when the item is pressed
    ###
    onPress = (e) ->
      element.addClass "draggable-active"
      draggable.start e
      DragAndDrop.setCurrentDraggable draggable
      DragAndDrop.trigger "drag-start", e
      # bind events for drag and release
      $document.on moveEvents, onMove
      $document.on releaseEvents, onRelease

    # initialize the draggable
    draggable.init element, processAttrs()
    DragAndDrop.addDraggable draggable
    element.on pressEvents, onPress

  # return the directive object
  return {
    restrict: "A"
    require: "draggable"
    controller: DraggableController
    controllerAs: "draggable"
    link: linkFunction
  }

draggableDirective.$inject =
  [ "$window", "$document", "$compile", "DragAndDrop" ]
angular
  .module "onlea.components.dnd"
  .directive "draggable", draggableDirective
