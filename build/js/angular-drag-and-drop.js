angular.module("onlea.components.dnd", []);


/*
 * Drag and Drop Service
 */
var DragAndDropService;

DragAndDropService = function($log) {
  var addAssignment, addDraggable, addDroppable, checkForIntersection, draggables, droppables, getCurrentDraggable, getCurrentDroppable, getEvent, getState, handlers, isDragging, isInside, isIntersecting, onEvent, options, removeAssignment, setCurrentDraggable, setCurrentDroppable, setEvent, state, trigger, uuid;
  handlers = [];
  draggables = [];
  droppables = [];
  options = {};
  state = {
    current: {
      draggable: null,
      droppable: null,
      event: null
    },
    dragging: false,
    ready: false,
    events: {}
  };
  uuid = function() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r, v;
      r = Math.random() * 16 | 0;
      v = c === 'x' ? r : r & 0x3 | 0x8;
      return v.toString(16);
    });
  };

  /*
   * Checks if a provided point is within the bounds object
   * @param {Point} point - array containing x and y coords
   * @param {DOMRect} bounds - object representing the rectangle bounds
   * @return {boolean} - true if the rectangles intersect
   */
  isInside = function(point, bounds) {
    var ref, ref1;
    return (bounds.left < (ref = point[0]) && ref < bounds.right) && (bounds.top < (ref1 = point[1]) && ref1 < bounds.bottom);
  };

  /*
   * Checks if two rectangles intersect each other
   * @param {DOMRect} r1 - object representing the first rectangle
   * @param {DOMRect} r2 - object representing the second rectangle
   * @return {boolean} - true if the rectangles intersect
   */
  isIntersecting = function(r1, r2) {
    return !(r2.left > r1.right || r2.right < r1.left || r2.top > r1.bottom || r2.bottom < r1.top);
  };

  /*
   * registers a callback function to a specific event
   * @param {string} eventName - event name to bind to
   * @param {function} cb - callback function to execute on the event
   */
  onEvent = function(eventName, cb) {
    if (cb) {
      if (eventName === "ready" && state.ready) {
        cb();
      }
      return handlers.push({
        name: eventName,
        cb: cb
      });
    }
  };

  /*
   * triggers the event handlers for the provided event name
   * @param {string} eventName - the event name to trigger
   * @param {Event} [eventData] - the event that caused the trigger
   */
  trigger = function(eventName, eventData) {
    var h, i, len, results;
    state = getState();
    $log.debug(eventName, state);
    if (eventName === "ready") {
      state.ready = true;
    }
    if (eventData) {
      setEvent(eventName, eventData);
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

  /*
   * gets the last event for the name given
   * @return the event corresponding to the name
   */
  getEvent = function(name) {
    if (state.events.hasOwnProperty(name)) {
      return state.events[name];
    }
  };

  /*
   * @return current state of the drag and drop
   */
  getState = function() {
    return state;
  };

  /*
   * @return {Draggable} the item that is currently being dragged
   */
  getCurrentDraggable = function() {
    return state.current.draggable;
  };

  /*
   * returns the drop spot that the current drag item is over
   * @return {Droppable} droppable the draggable is over
   */
  getCurrentDroppable = function() {
    return state.current.droppable;
  };

  /*
   * sets the event for the given name
   * @param {string} eventName - the name of the event
   * @param {Event} eventValue - thh event for eventName
   */
  setEvent = function(eventName, eventValue) {
    state.current.event = eventValue;
    return state.events[eventName] = eventValue;
  };

  /*
   * sets the current draggable
   * @param {Draggable} draggable - drag item to set
   */
  setCurrentDraggable = function(draggable) {
    return state.current.draggable = draggable;
  };

  /*
   * sets the current droppable
   * @param {Droppable} droppable - drop spot to set
   */
  setCurrentDroppable = function(droppable) {
    return state.current.droppable = droppable;
  };

  /*
   * assigns a drag item to a drop spot
   * @param {Draggable} draggable - drag item to remove
   * @param {Droppable} droppable - drop spot to remove from
   */
  addAssignment = function(draggable, droppable) {
    draggable.assignTo(droppable);
    droppable.addItem(draggable);
    return trigger('item-assigned', getEvent("drag-end"));
  };

  /*
   * removes a drag item from a drop spot
   * @param {Draggable} draggable - drag item to remove
   * @param {Droppable} droppable - drop spot to remove from
   */
  removeAssignment = function(draggable, droppable) {
    var i, item, len, ref, results;
    if (droppable) {
      draggable.removeFrom(droppable);
      droppable.removeItem(draggable);
      return trigger('item-removed', getEvent("drag-end"));
    } else {
      ref = draggable.getItems();
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        results.push(removeAssignment(draggable, item));
      }
      return results;
    }
  };

  /*
   * checks all of the drop spots to see if the currently dragged
   * item is overtop of them, uses the midpoint of the drag item.
   * fires the "drag-enter" and "drag-leave" events when entering and
   * leaving a drop spot.
   */
  checkForIntersection = function() {
    var droppable, i, len, results;
    results = [];
    for (i = 0, len = droppables.length; i < len; i++) {
      droppable = droppables[i];
      if (isInside(getCurrentDraggable().midPoint, droppable.getRect())) {
        if (!droppable.isActive) {
          setCurrentDroppable(droppable);
          droppable.activate();
          results.push(trigger('drag-enter', getEvent("drag")));
        } else {
          results.push(void 0);
        }
      } else {
        if (droppable.isActive) {
          setCurrentDroppable(null);
          droppable.deactivate();
          results.push(trigger('drag-leave', getEvent("drag")));
        } else {
          results.push(void 0);
        }
      }
    }
    return results;
  };

  /*
   * add a drop spot to the drag and drop
   * @param {Droppable} droppable - a drop spot
   */
  addDroppable = function(droppable) {
    return droppables.push(droppable);
  };

  /*
   * add a drag item to the drag and drop
   * @param {Draggable} draggable - a drag item
   */
  addDraggable = function(draggable) {
    return draggables.push(draggable);
  };

  /*
   * the dragging state
   * @return {boolean} - boolean value if dragging or not
   */
  isDragging = function() {
    return state.dragging;
  };
  onEvent("drag-start", function() {
    state.dragging = true;
    if (state.current.draggable) {
      removeAssignment(state.current.draggable);
    }
    return checkForIntersection();
  });
  onEvent("drag", function() {
    return checkForIntersection();
  });
  onEvent("drag-end", function() {
    var droppable, i, len;
    state.dragging = false;
    for (i = 0, len = droppables.length; i < len; i++) {
      droppable = droppables[i];
      if (droppable.isActive) {
        droppable.deactivate();
      }
    }
    if (state.current.droppable) {
      return addAssignment(state.current.draggable, state.current.droppable);
    }
  });
  return {
    uuid: uuid,
    on: onEvent,
    trigger: trigger,
    getState: getState,
    getCurrentDroppable: getCurrentDroppable,
    getCurrentDraggable: getCurrentDraggable,
    setCurrentDroppable: setCurrentDroppable,
    setCurrentDraggable: setCurrentDraggable,
    addDroppable: addDroppable,
    addDraggable: addDraggable,
    isDragging: isDragging
  };
};

DragAndDropService.$inject = ["$log"];

angular.module("onlea.components.dnd").factory("DragAndDrop", DragAndDropService);


/*
 * Draggable Directive Controller
 */
var DraggableController, draggableDirective;

DraggableController = function($document, $compile, DragAndDrop) {
  var createClone, current, draggableEl, getElementRect, getEventCoordinates, setElementTranslate, start, vm;
  draggableEl = null;
  vm = this;
  start = {
    rect: {},
    event: null
  };
  current = {
    rect: {},
    droppables: [],
    event: null
  };

  /*
   * gets the screen coordinates from a mouse or touch event
   */
  createClone = function() {
    var cloneEl;
    cloneEl = $compile(angular.element("<div>" + draggableEl.html() + "</div>"))(vm);
    cloneEl.addClass("clone");
    cloneEl.addClass(draggableEl.attr("class"));
    return $document.find("body").append(cloneEl);
  };

  /*
   * gets the screen coordinates from a mouse or touch event
   */
  getEventCoordinates = function(e) {
    if (e.touches && e.touches.length === 1) {
      return [e.touches[0].clientX, e.touches[0].clientY];
    } else {
      return [e.clientX, e.clientY];
    }
  };

  /*
   * gets the bounding DOMRect of an element
   * @param {jQlite Element} el - jquery (lite) wrapped element
   * @return {DOMRect} - screen boundary of element
   */
  getElementRect = function(el) {
    return el[0].getBoundingClientRect();
  };

  /*
   * sets the x / y translation of an element
   * @param {jQlite Element} el
   * @param {int} x - x translate pixels
   * @param {int} y - y translate pixels
   */
  setElementTranslate = function(el, x, y) {
    return el.css({
      "transform": "translate(" + x + "px, " + y + "px)",
      "-webkit-transform": "translate(" + x + "px, " + y + "px)",
      "-ms-transform": "translate(" + x + "px, " + y + "px)"
    });
  };

  /*
   * intitalizes the draggable
   */
  vm.init = function(element, options) {
    if (options == null) {
      options = {};
    }
    console.log("draggable init:", element, options);
    draggableEl = element;
    current.rect = getElementRect(draggableEl);
    if (options.id) {
      vm.id = options.id;
    } else {
      vm.id = DragAndDrop.uuid();
    }
    if (options.clone) {
      return createClone();
    }
  };

  /*
   * handler for when the drag starts
   */
  vm.start = function(e) {
    start.rect = getElementRect(draggableEl);
    start.event = e;
    return vm.midPoint = [start.rect.left + start.rect.width / 2, start.rect.top + start.rect.height / 2];
  };

  /*
   * handler for when moving the draggable
   */
  vm.move = function(e) {
    var currentCoords, startCoords, xPos, yPos;
    startCoords = getEventCoordinates(start.event);
    currentCoords = getEventCoordinates(e);
    xPos = start.rect.left + (currentCoords[0] - startCoords[0]);
    yPos = start.rect.top + (currentCoords[1] - startCoords[1]);
    setElementTranslate(draggableEl, xPos, yPos);
    current.event = e;
    current.rect.left = start.rect.left + xPos;
    current.rect.right = start.rect.right + xPos;
    current.rect.top = start.rect.top + yPos;
    current.rect.bottom = start.rect.bottom + yPos;
    return vm.midPoint = [xPos + start.rect.width / 2, yPos + start.rect.height / 2];
  };

  /*
   * handler for when moving the draggable
   */
  vm.assignTo = function(droppable) {
    current.droppables.push(droppable);
    return draggableEl.addClass("draggable-assigned");
  };

  /*
   * handler for when moving the draggable
   */
  vm.removeFrom = function(droppable) {
    var i, item, j, len, ref;
    ref = current.droppables;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      item = ref[i];
      current.droppables.splice(i, 1);
    }
    if (!(current.droppables.length > 0)) {
      return draggableEl.removeClass("draggable-assigned");
    }
  };
  vm.getItems = function() {
    return current.droppables;
  };

  /*
   * checks if the draggable is assigned or not
   */
  vm.isAssigned = function() {
    if (current.droppables.length > 0) {
      return true;
    }
    return false;
  };

  /*
   * get the current dimensions of the draggable
   */
  vm.getRect = function() {
    return current.rect;
  };
  return vm;
};

DraggableController.$inject = ["$document", "$compile", "DragAndDrop"];

draggableDirective = function($window, $document, $compile, DragAndDrop) {
  var linkFunction;
  linkFunction = function(scope, element, attrs, draggable) {
    var moveEvents, onMove, onPress, onRelease, pressEvents, processAttrs, releaseEvents;
    pressEvents = "touchstart mousedown";
    moveEvents = "touchmove mousemove";
    releaseEvents = "touchend mouseup";
    processAttrs = function() {
      var options;
      options = {};
      if (attrs.clone) {
        options.clone = true;
      }
      return options;
    };

    /*
     * handler for when the draggable is released
     * @param {Event} e - event when the item is released
     */
    onRelease = function(e) {
      element.removeClass("draggable-active");
      DragAndDrop.trigger("drag-end", e);
      DragAndDrop.setCurrentDraggable(null);
      $document.off(moveEvents, onMove);
      return $document.off(releaseEvents, onRelease);
    };

    /*
     * handler for when the draggable is moved
     * @param {Event} e - event when the item is released
     */
    onMove = function(e) {
      var currentDrop;
      draggable.move(e);
      DragAndDrop.trigger("drag", e);
      currentDrop = DragAndDrop.getCurrentDroppable();
      if (currentDrop) {
        return DragAndDrop.trigger("drag-in", e);
      } else {
        return DragAndDrop.trigger("drag-out", e);
      }
    };

    /*
     * handler for when the draggable is pressed
     * @param {Event} e - event when the item is pressed
     */
    onPress = function(e) {
      element.addClass("draggable-active");
      draggable.start(e);
      DragAndDrop.setCurrentDraggable(draggable);
      DragAndDrop.trigger("drag-start", e);
      $document.on(moveEvents, onMove);
      return $document.on(releaseEvents, onRelease);
    };
    draggable.init(element, processAttrs());
    DragAndDrop.addDraggable(draggable);
    return element.on(pressEvents, onPress);
  };
  return {
    restrict: "A",
    require: "draggable",
    controller: DraggableController,
    controllerAs: "draggable",
    link: linkFunction
  };
};

draggableDirective.$inject = ["$window", "$document", "$compile", "DragAndDrop"];

angular.module("onlea.components.dnd").directive("draggable", draggableDirective);

var DroppableController, droppableDirective;

DroppableController = function($log, DragAndDrop) {
  var current, droppableEl, vm;
  vm = this;
  droppableEl = null;
  current = {
    rect: {},
    draggables: []
  };

  /*
   * initialize the droppable area
   */
  vm.init = function(element, options) {
    $log.debug("droppable: init", element, options);
    droppableEl = element;
    vm.updateDimensions();
    if (options.id) {
      return vm.id = options.id;
    } else {
      return vm.id = DragAndDrop.uuid();
    }
  };

  /*
   * update the dimensions for the droppable area
   */
  vm.updateDimensions = function() {
    return current.rect = droppableEl[0].getBoundingClientRect();
  };

  /*
   * add a draggable to the drop spot
   */
  vm.addItem = function(draggable) {
    return current.draggables.push(draggable);
  };

  /*
   * remove a draggable from the drop spot
   */
  vm.removeItem = function(draggable) {
    var i, item, j, len, ref, results;
    ref = current.draggables;
    results = [];
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      item = ref[i];
      if (item.id === draggable.id) {
        results.push(current.draggables.splice(i, 1));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  /*
   * activate the drop spot
   */
  vm.activate = function() {
    vm.isActive = true;
    return droppableEl.addClass("droppable-hovered");
  };

  /*
   * deactivate the drop spot
   */
  vm.deactivate = function() {
    vm.isActive = false;
    return droppableEl.removeClass("droppable-hovered");
  };

  /*
   * get the DOMRect of the drop spot
   */
  vm.getRect = function() {
    return current.rect;
  };
  return vm;
};

DroppableController.$inject = ["$log", "DragAndDrop"];

droppableDirective = function($window, DragAndDrop) {
  var linkFunction;
  linkFunction = function(scope, element, attrs, droppable) {
    droppable.init(element, attrs);
    DragAndDrop.addDroppable(droppable);
    return $window.addEventListener("resize", function(e) {
      return droppable.updateDimensions();
    });
  };
  return {
    restrict: 'A',
    require: 'droppable',
    controller: DroppableController,
    controllerAs: 'droppable',
    link: linkFunction
  };
};

droppableDirective.$inject = ["$window", "DragAndDrop"];

angular.module("onlea.components.dnd").directive('droppable', droppableDirective);
