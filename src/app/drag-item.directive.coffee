DragItemController = ->

  el = null
  state =
    locked:
      horizontal: false
      vertical: false
  elRect = null
  startPosition = [0,0]
  transformEl = null

  vm = this
  vm.dropSpots = []
  vm.isAssigned = false

  vm.setDragId = () ->

  vm.setDragData = () ->



  vm.setStartPosition = (x,y) ->
    startPosition = [x,y]

  vm.setDragItemElement = (el) ->
    el = transformEl = el
    elRect = el[0].getBoundingClientRect()
    return vm

  vm.setTransformElement = (el) ->
    transformEl = el

  # update the element rectangle based on the x / y values
  vm.setDimensions = () ->
    vm.top = vm.y + elRect.top
    vm.left = vm.x + elRect.left
    vm.bottom = vm.top + elRect.height
    vm.right = vm.left + elRect.width
    vm.midPoint = [ (vm.left + vm.right)/2, (vm.top + vm.bottom)/2 ]
    if vm.isVerticallyLocked()
      # track the horizontal percentage position in the container
      # if we're locked vertically
      vm.percent = 100 *
        vm.midPoint[0] / el.parent()[0].clientWidth
      vm.percent = Math.min(100, Math.max(0, scope.percent))
    return vm

  vm.lockAxis = (axis) ->
    if axis is "horizontal" or "x"
      vm.state.locked.horizontal = true
    if axis is "vertical" or "y"
      vm.state.locked.vertical = true
    return vm

  vm.unlockAxis = (axis) ->
    if axis is "horizontal" or "x"
      vm.state.locked.horizontal = false
    if axis is "vertical" or "y"
      vm.state.locked.vertical = false
    return vm

  vm.isVerticallyLocked = ->
    return vm.state.locked.vertical

  vm.isHorizontallyLocked = ->
    return vm.state.locked.horizontal

  # set the position of an element based on a percentage
  # value, relative to the parent element
  vm.setPercentPostion = (xPercent,yPercent) ->
    newY = (el.parent()[0].clientHeight * (yPercent/100)) - el[0].clientHeight/2
    newX = (el.parent()[0].clientWidth * (xPercent/100)) - el[0].clientWidth/2
    vm.setPosition(newX, newY)
    return vm

  # set the position of the transform element
  vm.setPosition = (x, y) ->
    vm.x = if vm.isHorizontallyLocked() then 0 else x
    vm.y = if vm.isVerticallyLocked() then 0 else y
    vm.setDimensions()
    transformEl.css
      "transform": "translate(#{vm.x}px, #{vm.y}px)"
      "-webkit-transform": "translate(#{vm.x}px, #{vm.y}px)"
      "-ms-transform": "translate(#{vm.x}px, #{vm.y}px)"
    return vm

  # update the x / y offset of the drag item and set the style
  vm.updateOffset = (x,y) ->
    vm.setPosition(
      x - (eventOffset[0] + el[0].offsetLeft),
      y - (eventOffset[1] + el[0].offsetTop)
    )
    return vm

  # return the drag item to its original position
  vm.returnToStartPosition = ->
    scope.setPosition( startPosition[0], startPosition[1] )

  # assign the drag item to a drop spot
  vm.assignTo = (dropSpot) ->
    if dropSpot
      vm.dropSpots.push dropSpot
      vm.isAssigned = true
      if dropSpot.dropId
        el.addClass "in-#{dropSpot.dropId}"

  # finds the provided drop spot in the list of assigned drop spots
  # removes the drop spot from the list, and removes the draggable from
  # the drop spot.
  vm.removeFrom = (dropSpot) ->
    index = scope.dropSpots.indexOf dropSpot
    if index > -1
      if dropSpot.dropId
        el.removeClass "in-#{dropSpot.dropId}"
      scope.dropSpots.splice index, 1
      if scope.dropSpots.length < 1
        scope.isAssigned = false
      dropSpot.removeItem scope

  # removes the drag item from all of the drop spots
  vm.removeFromAll = ->
    for spot in scope.dropSpots
      scope.removeFrom spot

  vm.addClass = el.addClass
  vm.removeClass = el.removeClass
  vm.toggleClass = el.toggleClass

  # sets dragging status on the drag item
  vm.activate = ->
    el.addClass "drag-active"
    vm.isDragging = true

  # removes dragging status and resets the event offset
  vm.deactivate = () ->
    eventOffset = [0, 0]
    if vm.clone
      cloneEl.removeClass "clone-active"
    el.removeClass "drag-active"
    vm.isDragging = false

  return vm

# Drag Directive
# ----------
dragItemDirective = ($window, $document, $compile) ->
  restrict: 'EA'
  require: ['^dragAndDrop', 'dragItem']
  controller: DragItemController
  controllerAs: "drag"
  scope:
    x: "@"
    y: "@"
    dropTo: "@"
    dragId: "@"
    dragEnabled: "="
    dragData: "="
    clone: "="
    lockHorizontal: "="
    lockVertical: "="
  link: (scope, element, attrs, ctrls) ->

    # handle when a press event occurs
    onPress = (e) ->
      if scope.dragEnabled
        dnd.setCurrentDraggable drag
        dnd.trigger "drag-start", e

    # creates a clone of the drag item that is dragged, instead of transforming
    # the original element
    createClone = ->
      cloneEl =
        $compile(angular.element("<div>"+element.html()+"</div>"))(scope)
      cloneEl.addClass "clone"
      cloneEl.addClass element.attr "class"
      return cloneEl

    dnd = ctrls[0]
    drag = ctrls[1]

    pressEvents = "touchstart mousedown"
    drag.setStartPosition scope.x, scope.y
    dnd.addDraggable drag
    drag.setDragId scope.dragId
    drag.setDragData scope.dragData

    # bind press and window resize to the drag item
    element.on pressEvents, onPress
    $window.addEventListener "resize", drag.setDimensions

    # create the clone
    if scope.clone
      transformEl = createClone()
      dnd.addClone(transformEl)
      drag.setTransformElement(transformEl)

    # set the start position of the drag item
    drag.returnToStartPosition()

    scope.$on '$destroy', ->
      element.off pressEvents, onPress
      $window.removeEventListener "resize", drag.setDimensions

    # initialization
    dnd.on "ready", init

dragItemDirective.$inject '$window', '$document', '$compile'

angular.module "onlea.components.dnd"
  .directive 'dragItem', dragItemDirective
