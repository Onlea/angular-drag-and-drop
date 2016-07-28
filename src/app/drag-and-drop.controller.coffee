# Drag and Drop Controller
# ---
# contains all of the functions for the drag and drop

DragAndDropController = ($scope) ->

  # Checks if a provided point is within the bounds object
  isInside = (point, bounds) ->
    return (bounds.left < point[0] < bounds.right and
            bounds.top < point[1] < bounds.bottom)

  # Checks if two rectangles intersect each other
  isIntersecting = (r1, r2) ->
    return !(r2.left > r1.right or
             r2.right < r1.left or
             r2.top > r1.bottom or
             r2.bottom < r1.top)

  element = null
  isReady = false
  handlers = []
  eventList = {}

  vm = this
  vm.draggables = []
  vm.droppables = []
  vm.isDragging = false
  vm.currentDraggable = null
  vm.currentDroppable = null
  vm.fixedPositions = false

  # gets the last event for the name given
  vm.getEvent = (name) ->
    if eventList.hasOwnProperty name
      return eventList

  # get the element for the drag and drop
  vm.getDragAndDropElement = ->
    return element

  # gets the current state of the drag and drop
  vm.getState = () ->
    state =
      draggable: vm.getCurrentDraggable()
      droppable: vm.getCurrentDroppable()
    return state

  # @return {dragItem} the item that is currently being dragged
  vm.getCurrentDraggable = ->
    return vm.currentDraggable

  # returns the drop spot that the current drag item is over
  # @return {dropSpot} the item that is currently being dragged
  vm.getCurrentDroppable = () ->
    return vm.currentDroppable

  # check the status of the drag and drop to see if it's ready
  # @return {boolen} - true if ready
  vm.isReady = ->
    return isReady

  # sets the event for the given name
  vm.setEvent = (eventName, eventValue) ->
    eventList[eventName] = eventValue
    return vm

  # set the element for the drag and drop
  # @return {DragAndDropController} - returns this controller for chaining
  vm.setDragAndDropElement = (el) ->
    element = el
    return vm

  # sets if items should return to their start position when they are
  # not successfully assigned
  vm.setFixedPositions = (val) ->
    if val
      vm.fixedPositions = true
    else
      vm.fixedPositions = false
    return vm

  # sets the item that is currently being dragged, sets statuses
  # and fire the 'drag-start' callback
  # @return {DragAndDropController} - this controller
  vm.setCurrentDraggable = (draggable) ->
    vm.currentDraggable = draggable
    if draggable then vm.fireCallback 'drag-start'
    $scope.$evalAsync ->
      vm.currentDraggable = draggable
      if draggable
        vm.isDragging = true
      else
        vm.isDragging = false
    return vm

  # sets the drop spot that the current drag item is over
  # @return {DragAndDropController} - this controller
  vm.setCurrentDroppable = (droppable) ->
    vm.currentDroppable = droppable
    return vm

  handleMove = (state) ->
    draggable = state.draggable
    e = state.dragEvent
    if e.touches and e.touches.length is 1
      # update position based on touch event
      draggable.updateOffset e.touches[0].clientX, e.touches[0].clientY
    else
      # update position based on mouse event
      draggable.updateOffset e.clientX, e.clientY
    # check if dragging over a drop spot
    vm.checkForIntersection()

  # assigns the current draggable based on the current drop spot, if any
  handleRelease = (state) ->
    draggable = state.draggable
    dropSpot = state.droppable

    # deactivate the draggable
    draggable.deactivate()
    if dropSpot and not dropSpot.isFull
      # add the draggable to the drop spot if it isn't full
      vm.assignItem draggable, dropSpot
    else if dropSpot and dropSpot.isFull and scope.enableSwap
      # swap with the first drop spot item
      vm.swapItems(dropSpot.items[0], draggable)
    else
      # if released over nothing, remove the assignment
      vm.unassignItem draggabl
      if vm.fixedPositions then draggable.returnToStartPosition()
    if dropSpot then dropSpot.deactivate()
    vm.setCurrentDraggable null

  # removes an item from its drop spots
  # if a drop spot is passed, it is only removed from that drop spot
  vm.unassignItem = (dragItem, dropSpot) ->
    if dropSpot
      fromSpots = [ dropSpot ]
    else
      fromSpots = dragItem.dropSpots
    for spot in fromSpots
      dragItem.removeFrom(spot)
      vm.trigger 'item-removed', vm.getEvent "drag-end"

  vm.assignItem = (dragItem, dropSpot) ->
    dragItem.assignTo dropSpot
    dropSpot.itemDropped dragItem
    vm.trigger 'item-assigned', vm.getEvent "drag-end"

  # swaps item1 with item2
  vm.swapItems = (item1, item2) ->
    destination = []
    destination.push spot for spot in item1.dropSpots
    vm.unassignItem item1
    item1.returnToStartPosition()
    for destSpot in destination
      vm.assignItem item2, destSpot


  # registers a callback function to a specific event
  # @param {string} eventName - event name to bind to
  # @param {function} cb - callback function to execute on the event
  vm.on = (eventName, cb) ->
    # only add if there is a callback
    if cb
      # fire ready immediately if it's already ready
      if eventName is "ready" and isReady
        cb()
      handlers.push
        name: eventName
        cb: cb
    return vm

  # triggers the event handlers for the provided event name
  # @param {string} eventName - the event name to trigger
  vm.trigger = (eventName, eventData) ->
    state = vm.getState()
    if eventName is "ready" then isReady = true
    if eventData
      vm.setEvent name, eventData
      state.dragEvent = eventData
    for h in handlers
      if h.name is eventName then h.cb(state)

  # checks all of the drop spots to see if the currently dragged
  # item is overtop of them, uses the midpoint of the drag item.
  # fires the "drag-enter" and "drag-leave" events when entering and
  # leaving a drop spot.
  # @return {DragAndDropController} - this controller
  vm.checkForIntersection = ->
    for dropSpot in vm.droppables
      if isInside vm.currentDraggable.midPoint, dropSpot
        if !dropSpot.isActive
          vm.setCurrentDroppable dropSpot
          dropSpot.activate()
          vm.trigger 'drag-enter', vm.getEvent "drag"
      else
        if dropSpot.isActive
          @setCurrentDroppable null
          dropSpot.deactivate()
          vm.trigger 'drag-leave', vm.getEvent "drag"
    return vm

  # add a drop spot to the drag and drop
  # @return {DragAndDropController} - this controller
  vm.addDroppable = (droppable) ->
    vm.droppables.push droppable
    return vm

  # add a drag item to the drag and drop
  # @return {DragAndDropController} - this controller
  vm.addDraggable = (draggable) ->
    vm.draggables.push draggable
    return vm

  # add a drag item clone to the drag and drop container
  vm.addClone = (el) ->
    this.getDragAndDropElement().append el

  return vm


DragAndDropController.$inject = ["$scope"]
angular
  .module "onlea.components.dnd"
  .controller "DragAndDropController", DragAndDropController
