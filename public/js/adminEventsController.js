angular.module('aepi-fantasy').controller('AdminEventsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	updateEvents();
	updateLiveEvents();

	// Watches

	// Private Functions

	// Public Functions

	// Private Functions

	function updateEvents() {
		var Summary = $resource('/api/events/summary');
		var results = Summary.get(function() {
			$scope.eventTypes = results.eventTypes;
			$scope.summaries = results.eventSummaries;
		});
	}

	function updateLiveEvents() {
		var Live = $resource('/api/events/live/1');
		var results = Live.get(function() {
			$scope.events = results.events;
		});
	}
});