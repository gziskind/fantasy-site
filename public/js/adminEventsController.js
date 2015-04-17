angular.module('aepi-fantasy').controller('AdminEventsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	$scope.displayedEvents = []
	$scope.currentPage = 1;
	$scope.totalEvents = 0;
	$scope.numPages = 2;

	updateEvents();

	// Watches
	$scope.$watch('currentPage', setCurrentPage);

	// Private Functions

	// Public Functions
	$scope.checkAll = function() {
		if($scope.displayedEvents.length < $scope.eventTypes.length) {
			for(var c = 0; c < $scope.eventTypes.length; c++) {
				if($scope.displayedEvents.indexOf($scope.eventTypes[c]) == -1) {
					$scope.displayedEvents.push($scope.eventTypes[c]);
				}
			}
		} else {
			$scope.displayedEvents.length = 0;
		}
	}

	$scope.refreshLive = function() {
		$scope.refreshLoading = true;
		updateLiveEvents($scope.currentPage, function() {
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
	function setCurrentPage(newValue, oldValue) {
		updateLiveEvents($scope.currentPage);
	}

	function updateEvents() {
		var Summary = $resource('/api/events/summary');
		var results = Summary.get(function() {
			$scope.eventTypes = results.eventTypes;
			$scope.summaries = results.eventSummaries;
		});
	}

	function updateLiveEvents(currentPage, callback) {
		var Live = $resource('/api/events/live/' + currentPage);
		var results = Live.get(function() {
			if($scope.events && $scope.refreshLoading) {
				setNewEventsAfterTime(results.events, $scope.events[0].time);
			}

			$scope.events = results.events;
			$scope.totalEvents = results.count;

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