angular.module('aepi-fantasy').controller('RotoController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	$scope.contentLoaded = false;

	updateRotoData();

	// Public functions
	$scope.changeField = function(column) {
		if($scope.orderByField != column) {
			$scope.orderByField = column;
			$scope.reverseSort = true;
		} else {
			$scope.reverseSort = !$scope.reverseSort;
		}
	}
	
	$scope.sortStatus = function(column) {
		if($scope.orderByField == column) {
			if($scope.reverseSort) {
				return 'fa-sort-up';
			} else {
				return 'fa-sort-down';
			}
		} else {
			return '';
		}
	}
	
	// Watches

	// Private Functions
	function updateRotoData() {
		var RotoStandings = $resource('/api/baseball/results/roto');
		var results = RotoStandings.query(function() {
			$scope.standings = results;

			$scope.orderByField = "total_points";
			$scope.reverseSort = true;

			$scope.contentLoaded = true;
		});
	}
});