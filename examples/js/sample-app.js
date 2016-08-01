var app;

app = angular.module('example', ['onlea.components.dnd']);

app.controller("ExampleController", [
  '$scope', 'DragAndDrop', function($scope, DragAndDrop) {
    $scope.$on("drag-ready", function(e,d) { console.log("Drag ready", e,d); });
    $scope.logThis = function(message, draggable, droppable) {
      return console.log(message, {
        'draggable': draggable,
        'droppable': droppable
      });
    };
  }
]);
