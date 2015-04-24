angular.module('aepi-fantasy').controller('CareerStandingsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	$scope.contentLoaded = true;
	$scope.sport = $scope.$parent.getSportType()

	// updateRotoData();

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