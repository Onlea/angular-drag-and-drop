# # Drag and Drop Directive

dragAndDropDirective = ($document) ->

  linkFunction = (scope, element, attrs, dnd) ->

    moveEvents = "touchmove mousemove"
    releaseEvents = "touchend mouseup"
    dnd.setDragAndDropElement element
    dnd.setFixedPositions scope.fixedPositions

    $document.on moveEvents, onMove
    $document.on releaseEvents, onRelease

    # bind callbacks
    dnd.on "drag-start", -> $scope.onDragStart
    dnd.on "drag-end", -> $scope.onDragEnd
    dnd.on "drag", scope.onDrag
    dnd.on "item-assigned", scope.onItemPlaced
    dnd.on "item-removed", scope.onItemRemoved
    dnd.on "drag-leave", scope.onDragLeave
    dnd.on "drag-enter", scope.onDragEnter

    # add dragging class on element when dragging
    dnd.on "drag-start", -> element.addClass "dragging"
    dnd.on "drag-end", ->
      element.removeClass "dragging"
      element.addClass "drag-return"
      # NOTE: This is kind of a hack to allow the drag item to have
      # a return animation.  ngAnimate could be used for the animation
      # to prevent this.
      setTimeout ->
        element.removeClass "drag-return"
      , 500

    # handler for when a release event occures on the drag and drop element
    onRelease = (e) ->
      if dnd.getCurrentDraggable()
        dnd.trigger "drag-end", e

    # when an item is moved
    onMove = (e) ->
      if dnd.getCurrentDraggable()
        dnd.trigger "drag", e

    # unbinds events attached to the drag and drop container
    scope.$on "$destroy", ->
      $document.off moveEvents, onMove
      $document.off releaseEvents, onRelease

    dnd.trigger "ready"

  return {
    restrict: 'AE'
    scope:
      onItemPlaced: "&"
      onItemRemoved: "&"
      onDrag: "&"
      onDragStart: "&"
      onDragEnd: "&"
      onDragEnter: "&"
      onDragLeave: "&"
      enableSwap: "="
      fixedPositions: "="
    require: 'dragAndDrop'
    controller: DragAndDropController,
    controllerAs: 'dnd',
    link: linkFunction
  }

dragAndDropDirective.$inject = ['$document']
angular.module "onlea.components.dnd"
  .directive 'dragAndDrop', dragAndDropDirective
