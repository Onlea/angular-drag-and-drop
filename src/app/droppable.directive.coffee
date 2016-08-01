DroppableController = ($log, DragAndDrop) ->

  vm = this

  droppableEl = null

  current =
    rect: {}
    draggables: []

  ###
  # initialize the droppable area
  ###
  vm.init = (element, options) ->
    $log.debug "droppable: init", element, options
    droppableEl = element
    vm.updateDimensions()

  ###
  # update the dimensions for the droppable area
  ###
  vm.updateDimensions = ->
    current.rect = droppableEl[0].getBoundingClientRect()

  ###
  # add a draggable to the drop spot
  ###
  vm.addItem = (draggable) ->
    current.draggables.push draggable

  ###
  # remove a draggable from the drop spot
  ###
  vm.removeItem = (draggable) ->
    for item, i in current.draggables
      if item.id is draggable.id
        current.draggables.splice(i, 1)

  ###
  # activate the drop spot
  ###
  vm.activate = ->
    vm.isActive = true
    droppableEl.addClass "droppable-hovered"

  ###
  # deactivate the drop spot
  ###
  vm.deactivate = ->
    vm.isActive = false
    droppableEl.removeClass "droppable-hovered"

  ###
  # get the DOMRect of the drop spot
  ###
  vm.getRect = ->
    return current.rect

  return vm

DroppableController.$inject = [ "$log", "DragAndDrop" ]

droppableDirective = ($window, DragAndDrop) ->

  # initialization
  linkFunction = (scope, element, attrs, droppable) ->
    droppable.init element, attrs
    DragAndDrop.addDroppable droppable
    $window.addEventListener "resize", (e) ->
      droppable.updateDimensions()

  return {
    restrict: 'A'
    require: 'droppable'
    controller: DroppableController
    controllerAs: 'droppable'
    link: linkFunction
  }

droppableDirective.$inject = [ "$window", "DragAndDrop" ]
angular
  .module "onlea.components.dnd"
  .directive 'droppable', droppableDirective
