angular.module('aepi-fantasy').controller('AdminEventsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	updateEvents();
	updateLiveEvents();

	// Watches

	// Private Functions

	// Public Functions
	$scope.refreshLive = function() {
		$scope.refreshLoading = true;
		updateLiveEvents(function() {
			$scope.refreshLoading = false
		});
	}

	$scope.isNewEvent = function(user) {
		if(user.newEvent) {
			return 'new-event';
		} else {
			return '';
		}
	}

	// Private Functions

	function updateEvents() {
		var Summary = $resource('/api/events/summary');
		var results = Summary.get(function() {
			$scope.eventTypes = results.eventTypes;
			$scope.summaries = results.eventSummaries;
		});
	}

	function updateLiveEvents(callback) {
		var Live = $resource('/api/events/live/1');
		var results = Live.get(function() {
			if($scope.events) {
				setNewEventsAfterTime(results.events, $scope.events[0].time);
			}

			$scope.events = results.events;

			if(callback) {
				callback();
			}
		});
	}

	function setNewEventsAfterTime(newEvents, time) {
		for(var c = 0; c < newEvents.length; c++) {
			if(newEvents[c].time > time) {
				newEvents[c].newEvent = true;
			} else {
				break;
			}
		}
	}
});