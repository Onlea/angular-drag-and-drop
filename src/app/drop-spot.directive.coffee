
dropSpotDirective = [ '$window', ($window) ->
  restrict: 'AE'
  require: '^dragAndDrop'
  transclude: true
  template: "<div class='drop-content' ng-class='{ \"drop-full\": isFull }' "+
    "ng-transclude></div>"
  scope:
    dropId: "@"
    maxItems: "="
  link: (scope, element, attrs, ngDragAndDrop) ->

    updateDimensions = ->
      scope.left = element[0].offsetLeft
      scope.top = element[0].offsetTop
      scope.right = scope.left + element[0].offsetWidth
      scope.bottom = scope.top + element[0].offsetHeight

    # calculates where the item should be dropped to based on its config
    getDroppedPosition = (item) ->
      dropSize = [
        (scope.right-scope.left)
        (scope.bottom-scope.top)
      ]
      itemSize = [
        (item.right-item.left)
        (item.bottom-item.top)
      ]
      switch item.dropTo
        when "top"
          xPos = scope.left + (dropSize[0] - itemSize[0])/2
          yPos = scope.top
        when "bottom"
          xPos = scope.left + (dropSize[0] - itemSize[0])/2
          yPos = scope.top + (dropSize[1] - itemSize[1])
        when "left"
          xPos = scope.left
          yPos = scope.top + (dropSize[1] - itemSize[1])/2
        when "right"
          xPos = scope.left + (dropSize[0] - itemSize[0])
          yPos = scope.top + (dropSize[1] - itemSize[1])/2
        when "top left"
          xPos = scope.left
          yPos = scope.top
        when "bottom right"
          xPos = scope.left + (dropSize[0] - itemSize[0])
          yPos = scope.top + (dropSize[1] - itemSize[1])
        when "bottom left"
          xPos = scope.left
          yPos = scope.top + (dropSize[1] - itemSize[1])
        when "top right"
          xPos = scope.left + (dropSize[0] - itemSize[0])
          yPos = scope.top
        when "center"
          xPos = scope.left + (dropSize[0] - itemSize[0])/2
          yPos = scope.top + (dropSize[1] - itemSize[1])/2
        else
          if item.dropOffset
            xPos = scope.left + item.dropOffset[0]
            yPos = scope.top + item.dropOffset[1]

      return [xPos, yPos]

    scope.itemDropped = (item) ->
      added = addItem item
      if added
        if item.dropTo
          newPos = getDroppedPosition item
          item.updateOffset newPos[0], newPos[1]
        else
          item.dropOffset = [
            item.left - scope.left
            item.top - scope.top
          ]
      else
        if scope.fixedPositions
          item.returnToStartPosition()

    addItem = (item) ->
      unless scope.isFull
        scope.items.push item
        if scope.items.length >= scope.maxItems
          scope.isFull = true
        return item
      return false

    scope.removeItem = (item) ->
      index = scope.items.indexOf item
      if index > -1
        scope.items.splice index, 1
        if scope.items.length < scope.maxItems
          scope.isFull = false

    scope.activate = () ->
      scope.isActive = true
      element.addClass "drop-hovering"

    scope.deactivate = () ->
      scope.isActive = false
      ngDragAndDrop.setCurrentDroppable null
      element.removeClass "drop-hovering"

    handleResize = () ->
      updateDimensions()
      for item in scope.items
        newPos = getDroppedPosition(item)
        item.updateOffset newPos[0], newPos[1]

    bindEvents = ->
      w.bind "resize", handleResize

    unbindEvents = ->
      w.unbind "resize", handleResize

    if scope.dropId
      element.addClass scope.dropId

    w = angular.element $window
    bindEvents()

    scope.$on '$destroy', ->
      unbindEvents()

    # initialization
    updateDimensions()
    scope.isActive = false
    scope.items = []
    ngDragAndDrop.addDroppable scope

]
#
# angular.module "onlea.components.dnd"
#   .directive 'dropSpot', dropSpotDirective
