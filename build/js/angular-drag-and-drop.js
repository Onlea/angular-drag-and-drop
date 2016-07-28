angular.module("onlea.components.dnd", []);

var DragAndDropController;

DragAndDropController = function($scope) {
  var element, eventList, handleMove, handleRelease, handlers, isInside, isIntersecting, isReady, vm;
  isInside = function(point, bounds) {
    var ref, ref1;
    return (bounds.left < (ref = point[0]) && ref < bounds.right) && (bounds.top < (ref1 = point[1]) && ref1 < bounds.bottom);
  };
  isIntersecting = function(r1, r2) {
    return !(r2.left > r1.right || r2.right < r1.left || r2.top > r1.bottom || r2.bottom < r1.top);
  };
  element = null;
  isReady = false;
  handlers = [];
  eventList = {};
  vm = this;
  vm.draggables = [];
  vm.droppables = [];
  vm.isDragging = false;
  vm.currentDraggable = null;
  vm.currentDroppable = null;
  vm.fixedPositions = false;
  vm.getEvent = function(name) {
    if (eventList.hasOwnProperty(name)) {
      return eventList;
    }
  };
  vm.getDragAndDropElement = function() {
    return element;
  };
  vm.getState = function() {
    var state;
    state = {
      draggable: vm.getCurrentDraggable(),
      droppable: vm.getCurrentDroppable()
    };
    return state;
  };
  vm.getCurrentDraggable = function() {
    return vm.currentDraggable;
  };
  vm.getCurrentDroppable = function() {
    return vm.currentDroppable;
  };
  vm.isReady = function() {
    return isReady;
  };
  vm.setEvent = function(eventName, eventValue) {
    eventList[eventName] = eventValue;
    return vm;
  };
  vm.setDragAndDropElement = function(el) {
    element = el;
    return vm;
  };
  vm.setFixedPositions = function(val) {
    if (val) {
      vm.fixedPositions = true;
    } else {
      vm.fixedPositions = false;
    }
    return vm;
  };
  vm.setCurrentDraggable = function(draggable) {
    vm.currentDraggable = draggable;
    if (draggable) {
      vm.fireCallback('drag-start');
    }
    $scope.$evalAsync(function() {
      vm.currentDraggable = draggable;
      if (draggable) {
        return vm.isDragging = true;
      } else {
        return vm.isDragging = false;
      }
    });
    return vm;
  };
  vm.setCurrentDroppable = function(droppable) {
    vm.currentDroppable = droppable;
    return vm;
  };
  handleMove = function(state) {
    var draggable, e;
    draggable = state.draggable;
    e = state.dragEvent;
    if (e.touches && e.touches.length === 1) {
      draggable.updateOffset(e.touches[0].clientX, e.touches[0].clientY);
    } else {
      draggable.updateOffset(e.clientX, e.clientY);
    }
    return vm.checkForIntersection();
  };
  handleRelease = function(state) {
    var draggable, dropSpot;
    draggable = state.draggable;
    dropSpot = state.droppable;
    draggable.deactivate();
    if (dropSpot && !dropSpot.isFull) {
      vm.assignItem(draggable, dropSpot);
    } else if (dropSpot && dropSpot.isFull && scope.enableSwap) {
      vm.swapItems(dropSpot.items[0], draggable);
    } else {
      vm.unassignItem(draggabl);
      if (vm.fixedPositions) {
        draggable.returnToStartPosition();
      }
    }
    if (dropSpot) {
      dropSpot.deactivate();
    }
    return vm.setCurrentDraggable(null);
  };
  vm.unassignItem = function(dragItem, dropSpot) {
    var fromSpots, i, len, results, spot;
    if (dropSpot) {
      fromSpots = [dropSpot];
    } else {
      fromSpots = dragItem.dropSpots;
    }
    results = [];
    for (i = 0, len = fromSpots.length; i < len; i++) {
      spot = fromSpots[i];
      dragItem.removeFrom(spot);
      results.push(vm.trigger('item-removed', vm.getEvent("drag-end")));
    }
    return results;
  };
  vm.assignItem = function(dragItem, dropSpot) {
    dragItem.assignTo(dropSpot);
    dropSpot.itemDropped(dragItem);
    return vm.trigger('item-assigned', vm.getEvent("drag-end"));
  };
  vm.swapItems = function(item1, item2) {
    var destSpot, destination, i, j, len, len1, ref, results, spot;
    destination = [];
    ref = item1.dropSpots;
    for (i = 0, len = ref.length; i < len; i++) {
      spot = ref[i];
      destination.push(spot);
    }
    vm.unassignItem(item1);
    item1.returnToStartPosition();
    results = [];
    for (j = 0, len1 = destination.length; j < len1; j++) {
      destSpot = destination[j];
      results.push(vm.assignItem(item2, destSpot));
    }
    return results;
  };
  vm.on = function(eventName, cb) {
    if (cb) {
      if (eventName === "ready" && isReady) {
        cb();
      }
      handlers.push({
        name: eventName,
        cb: cb
      });
    }
    return vm;
  };
  vm.trigger = function(eventName, eventData) {
    var h, i, len, results, state;
    state = vm.getState();
    if (eventName === "ready") {
      isReady = true;
    }
    if (eventData) {
      vm.setEvent(name, eventData);
      state.dragEvent = eventData;
    }
    results = [];
    for (i = 0, len = handlers.length; i < len; i++) {
      h = handlers[i];
      if (h.name === eventName) {
        results.push(h.cb(state));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };
  vm.checkForIntersection = function() {
    var dropSpot, i, len, ref;
    ref = vm.droppables;
    for (i = 0, len = ref.length; i < len; i++) {
      dropSpot = ref[i];
      if (isInside(vm.currentDraggable.midPoint, dropSpot)) {
        if (!dropSpot.isActive) {
          vm.setCurrentDroppable(dropSpot);
          dropSpot.activate();
          vm.trigger('drag-enter', vm.getEvent("drag"));
        }
      } else {
        if (dropSpot.isActive) {
          this.setCurrentDroppable(null);
          dropSpot.deactivate();
          vm.trigger('drag-leave', vm.getEvent("drag"));
        }
      }
    }
    return vm;
  };
  vm.addDroppable = function(droppable) {
    vm.droppables.push(droppable);
    return vm;
  };
  vm.addDraggable = function(draggable) {
    vm.draggables.push(draggable);
    return vm;
  };
  vm.addClone = function(el) {
    return this.getDragAndDropElement().append(el);
  };
  return vm;
};

DragAndDropController.$inject = ["$scope"];

angular.module("onlea.components.dnd").controller("DragAndDropController", DragAndDropController);

var dragAndDropDirective;

dragAndDropDirective = function($document) {
  var linkFunction;
  linkFunction = function(scope, element, attrs, dnd) {
    var moveEvents, onMove, onRelease, releaseEvents;
    moveEvents = "touchmove mousemove";
    releaseEvents = "touchend mouseup";
    dnd.setDragAndDropElement(element);
    dnd.setFixedPositions(scope.fixedPositions);
    $document.on(moveEvents, onMove);
    $document.on(releaseEvents, onRelease);
    dnd.on("drag-start", function() {
      return $scope.onDragStart;
    });
    dnd.on("drag-end", function() {
      return $scope.onDragEnd;
    });
    dnd.on("drag", scope.onDrag);
    dnd.on("item-assigned", scope.onItemPlaced);
    dnd.on("item-removed", scope.onItemRemoved);
    dnd.on("drag-leave", scope.onDragLeave);
    dnd.on("drag-enter", scope.onDragEnter);
    dnd.on("drag-start", function() {
      return element.addClass("dragging");
    });
    dnd.on("drag-end", function() {
      element.removeClass("dragging");
      element.addClass("drag-return");
      return setTimeout(function() {
        return element.removeClass("drag-return");
      }, 500);
    });
    onRelease = function(e) {
      if (dnd.getCurrentDraggable()) {
        return dnd.trigger("drag-end", e);
      }
    };
    onMove = function(e) {
      if (dnd.getCurrentDraggable()) {
        return dnd.trigger("drag", e);
      }
    };
    scope.$on("$destroy", function() {
      $document.off(moveEvents, onMove);
      return $document.off(releaseEvents, onRelease);
    });
    return dnd.trigger("ready");
  };
  return {
    restrict: 'AE',
    scope: {
      onItemPlaced: "&",
      onItemRemoved: "&",
      onDrag: "&",
      onDragStart: "&",
      onDragEnd: "&",
      onDragEnter: "&",
      onDragLeave: "&",
      enableSwap: "=",
      fixedPositions: "="
    },
    require: 'dragAndDrop',
    controller: DragAndDropController,
    controllerAs: 'dnd',
    link: linkFunction
  };
};

dragAndDropDirective.$inject = ['$document'];

angular.module("onlea.components.dnd").directive('dragAndDrop', dragAndDropDirective);

var DragItemController, dragItemDirective;

DragItemController = function() {
  var el, elRect, startPosition, state, transformEl, vm;
  el = null;
  state = {
    locked: {
      horizontal: false,
      vertical: false
    }
  };
  elRect = null;
  startPosition = [0, 0];
  transformEl = null;
  vm = this;
  vm.dropSpots = [];
  vm.isAssigned = false;
  vm.setDragId = function() {};
  vm.setDragData = function() {};
  vm.setStartPosition = function(x, y) {
    return startPosition = [x, y];
  };
  vm.setDragItemElement = function(el) {
    el = transformEl = el;
    elRect = el[0].getBoundingClientRect();
    return vm;
  };
  vm.setTransformElement = function(el) {
    return transformEl = el;
  };
  vm.setDimensions = function() {
    vm.top = vm.y + elRect.top;
    vm.left = vm.x + elRect.left;
    vm.bottom = vm.top + elRect.height;
    vm.right = vm.left + elRect.width;
    vm.midPoint = [(vm.left + vm.right) / 2, (vm.top + vm.bottom) / 2];
    if (vm.isVerticallyLocked()) {
      vm.percent = 100 * vm.midPoint[0] / el.parent()[0].clientWidth;
      vm.percent = Math.min(100, Math.max(0, scope.percent));
    }
    return vm;
  };
  vm.lockAxis = function(axis) {
    if (axis === "horizontal" || "x") {
      vm.state.locked.horizontal = true;
    }
    if (axis === "vertical" || "y") {
      vm.state.locked.vertical = true;
    }
    return vm;
  };
  vm.unlockAxis = function(axis) {
    if (axis === "horizontal" || "x") {
      vm.state.locked.horizontal = false;
    }
    if (axis === "vertical" || "y") {
      vm.state.locked.vertical = false;
    }
    return vm;
  };
  vm.isVerticallyLocked = function() {
    return vm.state.locked.vertical;
  };
  vm.isHorizontallyLocked = function() {
    return vm.state.locked.horizontal;
  };
  vm.setPercentPostion = function(xPercent, yPercent) {
    var newX, newY;
    newY = (el.parent()[0].clientHeight * (yPercent / 100)) - el[0].clientHeight / 2;
    newX = (el.parent()[0].clientWidth * (xPercent / 100)) - el[0].clientWidth / 2;
    vm.setPosition(newX, newY);
    return vm;
  };
  vm.setPosition = function(x, y) {
    vm.x = vm.isHorizontallyLocked() ? 0 : x;
    vm.y = vm.isVerticallyLocked() ? 0 : y;
    vm.setDimensions();
    transformEl.css({
      "transform": "translate(" + vm.x + "px, " + vm.y + "px)",
      "-webkit-transform": "translate(" + vm.x + "px, " + vm.y + "px)",
      "-ms-transform": "translate(" + vm.x + "px, " + vm.y + "px)"
    });
    return vm;
  };
  vm.updateOffset = function(x, y) {
    vm.setPosition(x - (eventOffset[0] + el[0].offsetLeft), y - (eventOffset[1] + el[0].offsetTop));
    return vm;
  };
  vm.returnToStartPosition = function() {
    return scope.setPosition(startPosition[0], startPosition[1]);
  };
  vm.assignTo = function(dropSpot) {
    if (dropSpot) {
      vm.dropSpots.push(dropSpot);
      vm.isAssigned = true;
      if (dropSpot.dropId) {
        return el.addClass("in-" + dropSpot.dropId);
      }
    }
  };
  vm.removeFrom = function(dropSpot) {
    var index;
    index = scope.dropSpots.indexOf(dropSpot);
    if (index > -1) {
      if (dropSpot.dropId) {
        el.removeClass("in-" + dropSpot.dropId);
      }
      scope.dropSpots.splice(index, 1);
      if (scope.dropSpots.length < 1) {
        scope.isAssigned = false;
      }
      return dropSpot.removeItem(scope);
    }
  };
  vm.removeFromAll = function() {
    var i, len, ref, results, spot;
    ref = scope.dropSpots;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      spot = ref[i];
      results.push(scope.removeFrom(spot));
    }
    return results;
  };
  vm.addClass = el.addClass;
  vm.removeClass = el.removeClass;
  vm.toggleClass = el.toggleClass;
  vm.activate = function() {
    el.addClass("drag-active");
    return vm.isDragging = true;
  };
  vm.deactivate = function() {
    var eventOffset;
    eventOffset = [0, 0];
    if (vm.clone) {
      cloneEl.removeClass("clone-active");
    }
    el.removeClass("drag-active");
    return vm.isDragging = false;
  };
  return vm;
};

dragItemDirective = function($window, $document, $compile) {
  return {
    restrict: 'EA',
    require: ['^dragAndDrop', 'dragItem'],
    controller: DragItemController,
    controllerAs: "drag",
    scope: {
      x: "@",
      y: "@",
      dropTo: "@",
      dragId: "@",
      dragEnabled: "=",
      dragData: "=",
      clone: "=",
      lockHorizontal: "=",
      lockVertical: "="
    },
    link: function(scope, element, attrs, ctrls) {
      var createClone, dnd, drag, onPress, pressEvents, transformEl;
      onPress = function(e) {
        if (scope.dragEnabled) {
          dnd.setCurrentDraggable(drag);
          return dnd.trigger("drag-start", e);
        }
      };
      createClone = function() {
        var cloneEl;
        cloneEl = $compile(angular.element("<div>" + element.html() + "</div>"))(scope);
        cloneEl.addClass("clone");
        cloneEl.addClass(element.attr("class"));
        return cloneEl;
      };
      dnd = ctrls[0];
      drag = ctrls[1];
      pressEvents = "touchstart mousedown";
      drag.setStartPosition(scope.x, scope.y);
      dnd.addDraggable(drag);
      drag.setDragId(scope.dragId);
      drag.setDragData(scope.dragData);
      element.on(pressEvents, onPress);
      $window.addEventListener("resize", drag.setDimensions);
      if (scope.clone) {
        transformEl = createClone();
        dnd.addClone(transformEl);
        drag.setTransformElement(transformEl);
      }
      drag.returnToStartPosition();
      scope.$on('$destroy', function() {
        element.off(pressEvents, onPress);
        return $window.removeEventListener("resize", drag.setDimensions);
      });
      return dnd.on("ready", init);
    }
  };
};

dragItemDirective.$inject('$window', '$document', '$compile');

angular.module("onlea.components.dnd").directive('dragItem', dragItemDirective);

var dropSpotDirective;

dropSpotDirective = [
  '$window', function($window) {
    return {
      restrict: 'AE',
      require: '^dragAndDrop',
      transclude: true,
      template: "<div class='drop-content' ng-class='{ \"drop-full\": isFull }' " + "ng-transclude></div>",
      scope: {
        dropId: "@",
        maxItems: "="
      },
      link: function(scope, element, attrs, ngDragAndDrop) {
        var addItem, bindEvents, getDroppedPosition, handleResize, unbindEvents, updateDimensions, w;
        updateDimensions = function() {
          scope.left = element[0].offsetLeft;
          scope.top = element[0].offsetTop;
          scope.right = scope.left + element[0].offsetWidth;
          return scope.bottom = scope.top + element[0].offsetHeight;
        };
        getDroppedPosition = function(item) {
          var dropSize, itemSize, xPos, yPos;
          dropSize = [scope.right - scope.left, scope.bottom - scope.top];
          itemSize = [item.right - item.left, item.bottom - item.top];
          switch (item.dropTo) {
            case "top":
              xPos = scope.left + (dropSize[0] - itemSize[0]) / 2;
              yPos = scope.top;
              break;
            case "bottom":
              xPos = scope.left + (dropSize[0] - itemSize[0]) / 2;
              yPos = scope.top + (dropSize[1] - itemSize[1]);
              break;
            case "left":
              xPos = scope.left;
              yPos = scope.top + (dropSize[1] - itemSize[1]) / 2;
              break;
            case "right":
              xPos = scope.left + (dropSize[0] - itemSize[0]);
              yPos = scope.top + (dropSize[1] - itemSize[1]) / 2;
              break;
            case "top left":
              xPos = scope.left;
              yPos = scope.top;
              break;
            case "bottom right":
              xPos = scope.left + (dropSize[0] - itemSize[0]);
              yPos = scope.top + (dropSize[1] - itemSize[1]);
              break;
            case "bottom left":
              xPos = scope.left;
              yPos = scope.top + (dropSize[1] - itemSize[1]);
              break;
            case "top right":
              xPos = scope.left + (dropSize[0] - itemSize[0]);
              yPos = scope.top;
              break;
            case "center":
              xPos = scope.left + (dropSize[0] - itemSize[0]) / 2;
              yPos = scope.top + (dropSize[1] - itemSize[1]) / 2;
              break;
            default:
              if (item.dropOffset) {
                xPos = scope.left + item.dropOffset[0];
                yPos = scope.top + item.dropOffset[1];
              }
          }
          return [xPos, yPos];
        };
        scope.itemDropped = function(item) {
          var added, newPos;
          added = addItem(item);
          if (added) {
            if (item.dropTo) {
              newPos = getDroppedPosition(item);
              return item.updateOffset(newPos[0], newPos[1]);
            } else {
              return item.dropOffset = [item.left - scope.left, item.top - scope.top];
            }
          } else {
            if (scope.fixedPositions) {
              return item.returnToStartPosition();
            }
          }
        };
        addItem = function(item) {
          if (!scope.isFull) {
            scope.items.push(item);
            if (scope.items.length >= scope.maxItems) {
              scope.isFull = true;
            }
            return item;
          }
          return false;
        };
        scope.removeItem = function(item) {
          var index;
          index = scope.items.indexOf(item);
          if (index > -1) {
            scope.items.splice(index, 1);
            if (scope.items.length < scope.maxItems) {
              return scope.isFull = false;
            }
          }
        };
        scope.activate = function() {
          scope.isActive = true;
          return element.addClass("drop-hovering");
        };
        scope.deactivate = function() {
          scope.isActive = false;
          ngDragAndDrop.setCurrentDroppable(null);
          return element.removeClass("drop-hovering");
        };
        handleResize = function() {
          var i, item, len, newPos, ref, results;
          updateDimensions();
          ref = scope.items;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            item = ref[i];
            newPos = getDroppedPosition(item);
            results.push(item.updateOffset(newPos[0], newPos[1]));
          }
          return results;
        };
        bindEvents = function() {
          return w.bind("resize", handleResize);
        };
        unbindEvents = function() {
          return w.unbind("resize", handleResize);
        };
        if (scope.dropId) {
          element.addClass(scope.dropId);
        }
        w = angular.element($window);
        bindEvents();
        scope.$on('$destroy', function() {
          return unbindEvents();
        });
        updateDimensions();
        scope.isActive = false;
        scope.items = [];
        return ngDragAndDrop.addDroppable(scope);
      }
    };
  }
];
