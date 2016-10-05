###
# Drag and Drop Service
###
DragAndDropService = ($log)->

  handlers = [] # stores event handlers
  draggables = [] # stores draggable items
  droppables = [] # stores droppable items
  options = {} # options for the service

  # state of the drag and drop
  state =
    current:
      draggable: null
      droppable: null
      event: null
    dragging: false
    ready:false
    events: {}

  # RFC1422-compliant Javascript UUID function. Generates a UUID from a random
  # number (which means it might not be entirely unique, though it should be
  # good enough for many uses). See http://stackoverflow.com/questions/105034
  uuid = ->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else (r & 0x3|0x8)
      v.toString(16)
    )

  ###*
  # Checks if a provided point is within the bounds object
  # @param {Point} point - array containing x and y coords
  # @param {DOMRect} bounds - object representing the rectangle bounds
  # @return {boolean} - true if the rectangles intersect
  ###
  isInside = (point, bounds) ->
    return (bounds.left < point[0] < bounds.right and
            bounds.top < point[1] < bounds.bottom)

  ###*
  # Checks if two rectangles intersect each other
  # @param {DOMRect} r1 - object representing the first rectangle
  # @param {DOMRect} r2 - object representing the second rectangle
  # @return {boolean} - true if the rectangles intersect
  ###
  isIntersecting = (r1, r2) ->
    return !(r2.left > r1.right or
             r2.right < r1.left or
             r2.top > r1.bottom or
             r2.bottom < r1.top)


  ###*
  # registers a callback function to a specific event
  # @param {string} eventName - event name to bind to
  # @param {function} cb - callback function to execute on the event
  ###
  onEvent = (eventName, cb) ->
    # only add if there is a callback
    if cb
      # fire ready immediately if it's already ready
      if eventName is "ready" and state.ready then cb()
      handlers.push
        name: eventName
        cb: cb

  ###*
  # triggers the event handlers for the provided event name
  # @param {string} eventName - the event name to trigger
  # @param {Event} [eventData] - the event that caused the trigger
  ###
  trigger = (eventName, eventData) ->
    state = getState()
    $log.debug eventName, state
    if eventName is "ready" then state.ready = true
    if eventData then setEvent eventName, eventData
    for h in handlers
      if h.name is eventName then h.cb(state)

  ###*
  # gets the last event for the name given
  # @return the event corresponding to the name
  ###
  getEvent = (name) ->
    if state.events.hasOwnProperty name
      return state.events[name]

  ###*
  # @return current state of the drag and drop
  ###
  getState = ->
    return state

  ###*
  # @return {Draggable} the item that is currently being dragged
  ###
  getCurrentDraggable = ->
    return state.current.draggable

  ###*
  # returns the drop spot that the current drag item is over
  # @return {Droppable} droppable the draggable is over
  ###
  getCurrentDroppable = ->
    return state.current.droppable

  ###*
  # sets the event for the given name
  # @param {string} eventName - the name of the event
  # @param {Event} eventValue - thh event for eventName
  ###
  setEvent = (eventName, eventValue) ->
    state.current.event = eventValue
    state.events[eventName] = eventValue

  ###*
  # sets the current draggable
  # @param {Draggable} draggable - drag item to set
  ###
  setCurrentDraggable = (draggable) ->
    state.current.draggable = draggable

  ###*
  # sets the current droppable
  # @param {Droppable} droppable - drop spot to set
  ###
  setCurrentDroppable = (droppable) ->
    state.current.droppable = droppable

  ###*
  # assigns a drag item to a drop spot
  # @param {Draggable} draggable - drag item to remove
  # @param {Droppable} droppable - drop spot to remove from
  ###
  addAssignment = (draggable, droppable) ->
    draggable.assignTo droppable
    droppable.addItem draggable
    trigger 'item-assigned', getEvent "drag-end"

  ###*
  # removes a drag item from a drop spot
  # @param {Draggable} draggable - drag item to remove
  # @param {Droppable} droppable - drop spot to remove from
  ###
  removeAssignment = (draggable, droppable) ->
    if droppable
      draggable.removeFrom droppable
      droppable.removeItem draggable
      trigger 'item-removed', getEvent "drag-end"
    else
      for item in draggable.getItems()
        removeAssignment draggable, item

  ###*
  # checks all of the drop spots to see if the currently dragged
  # item is overtop of them, uses the midpoint of the drag item.
  # fires the "drag-enter" and "drag-leave" events when entering and
  # leaving a drop spot.
  ###
  checkForIntersection = ->
    for droppable in droppables
      if isInside getCurrentDraggable().midPoint, droppable.getRect()
        if !droppable.isActive
          setCurrentDroppable droppable
          droppable.activate()
          trigger 'drag-enter', getEvent "drag"
      else
        if droppable.isActive
          setCurrentDroppable null
          droppable.deactivate()
          trigger 'drag-leave', getEvent "drag"

  ###*
  # add a drop spot to the drag and drop
  # @param {Droppable} droppable - a drop spot
  ###
  addDroppable = (droppable) ->
    droppables.push droppable

  ###*
  # add a drag item to the drag and drop
  # @param {Draggable} draggable - a drag item
  ###
  addDraggable = (draggable) ->
    draggables.push draggable

  ###*
  # the dragging state
  # @return {boolean} - boolean value if dragging or not
  ###
  isDragging = -> state.dragging

  # set the dragging state and remove assignment on drag start
  onEvent "drag-start", ->
    state.dragging = true
    if state.current.draggable
      removeAssignment state.current.draggable
    checkForIntersection()

  # check for intersecting items on drag
  onEvent "drag", ->
    checkForIntersection()

  # set the dragging state to false and add assignment if any
  onEvent "drag-end", ->
    state.dragging = false
    for droppable in droppables
      if droppable.isActive
        droppable.deactivate()
    if state.current.droppable
      addAssignment state.current.draggable, state.current.droppable

  # expose service methods
  return {
    uuid: uuid
    on: onEvent
    trigger: trigger
    getState: getState
    getCurrentDroppable: getCurrentDroppable
    getCurrentDraggable: getCurrentDraggable
    setCurrentDroppable: setCurrentDroppable
    setCurrentDraggable: setCurrentDraggable
    addDroppable: addDroppable
    addDraggable: addDraggable
    isDragging: isDragging
  }

DragAndDropService.$inject = [ "$log" ]

angular
  .module "onlea.components.dnd"
  .factory "DragAndDrop", DragAndDropService
