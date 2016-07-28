var app;

app = angular.module('example', ['onlea.components.dnd']);

app.controller("ExampleController", [
  '$scope', function($scope) {
    $scope.$on("drag-ready", function(e,d) { console.log("Drag ready", e,d); });
    return $scope.logThis = function(message, draggable, droppable) {
      return console.log(message, {
        'draggable': draggable,
        'droppable': droppable
      });
    };
  }
]);
