angular.module('aepi-fantasy').controller('RotoController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	$scope.contentLoaded = true;

	updateRotoData();

	// Public functions
	
	// Watches

	// Private Functions
	function updateRotoData() {
		var RotoStandings = $resource('/api/baseball/results/roto');
		var results = RotoStandings.query(function() {
			$scope.standings = results;
		});
	}
});