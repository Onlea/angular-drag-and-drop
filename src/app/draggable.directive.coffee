###
# Draggable Directive Controller
###
DraggableController = (DragAndDrop) ->

  draggableEl = null # the element to drag
  vm = this # view model for the controller

  # object for storing the start state when dragging
  start =
    rect: {}
    event: null

  # object for storing the current state when dragging
  current =
    rect: {}
    droppables: []
    event: null

  ###
  # gets the screen coordinates from a mouse or touch event
  ###
  getEventCoordinates = (e) ->
    if e.touches and e.touches.length is 1
      return [ e.touches[0].clientX, e.touches[0].clientY ]
    else
      return [ e.clientX, e.clientY ]

  ###
  # gets the bounding DOMRect of an element
  # @param {jQlite Element} el - jquery (lite) wrapped element
  # @return {DOMRect} - screen boundary of element
  ###
  getElementRect = (el) -> el[0].getBoundingClientRect()

  ###
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

  ###
  # intitalizes the draggable
  ###
  vm.init = (element, options) ->
    console.log "draggable init:", element, options
    draggableEl = element
    current.rect = getElementRect draggableEl

  ###
  # handler for when the drag starts
  ###
  vm.start = (e) ->
    start.rect = getElementRect draggableEl
    start.event = e
    vm.midPoint = [
      start.rect.left + start.rect.width/2,
      start.rect.top + start.rect.height/2
    ]

  ###
  # handler for when moving the draggable
  ###
  vm.move = (e) ->
    # console.log "move:", e
    startCoords = getEventCoordinates start.event
    currentCoords = getEventCoordinates e
    xPos = start.rect.left + (currentCoords[0] - startCoords[0])
    yPos = start.rect.top + (currentCoords[1] - startCoords[1])
    setElementTranslate draggableEl, xPos, yPos
    current.event = e
    current.rect.left = start.rect.left + xPos
    current.rect.right = start.rect.right + xPos
    current.rect.top = start.rect.top + yPos
    current.rect.bottom = start.rect.bottom + yPos
    vm.midPoint = [
      xPos+start.rect.width/2,
      yPos+start.rect.height/2
    ]

  ###
  # handler for when moving the draggable
  ###
  vm.assignTo = (droppable) ->
    current.droppables.push droppable
    draggableEl.addClass "draggable-assigned"

  ###
  # handler for when moving the draggable
  ###
  vm.removeFrom = (droppable) ->
    for item,i in current.droppables
      current.droppables.splice(i,1)
    unless current.droppables.length > 0
      draggableEl.removeClass "draggable-assigned"

  vm.getItems = ->
    return current.droppables

  ###
  # checks if the draggable is assigned or not
  ###
  vm.isAssigned = ->
    if current.droppables.length > 0
      return true
    return false

  ###
  # get the current dimensions of the draggable
  ###
  vm.getRect = ->
    return current.rect

  return vm

DraggableController.$inject = [ "DragAndDrop" ]

draggableDirective = ($window, $document, $compile, DragAndDrop) ->

  linkFunction = (scope, element, attrs, draggable) ->

    pressEvents = "touchstart mousedown"
    moveEvents = "touchmove mousemove"
    releaseEvents = "touchend mouseup"

    ###
    # handler for when the draggable is released
    # @param {Event} e - event when the item is released
    ###
    onRelease = (e) ->
      element.removeClass "draggable-active"
      DragAndDrop.trigger "drag-end", e
      DragAndDrop.setCurrentDraggable null
      $document.off moveEvents, onMove
      $document.off releaseEvents, onRelease

    ###
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

    ###
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
    draggable.init element, scope
    DragAndDrop.addDraggable draggable
    element.on pressEvents, onPress
    $window.addEventListener "resize", (e) ->
      draggable.updateDimensions()

  # return the directive object
  return {
    restrict: "A"
    require: "draggable"
    controller: DraggableController
    controllerAs: "draggable"
    link: linkFunction
  }

draggableDirective.$inject = [ "$window", "$document", "$compile", "DragAndDrop" ]
angular
  .module "onlea.components.dnd"
  .directive "draggable", draggableDirective
