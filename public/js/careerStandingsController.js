angular.module('aepi-fantasy').controller('CareerStandingsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables

	// Public variables
	$scope.contentLoaded = true;
	$scope.sport = $scope.$parent.getSportType()

	// updateRotoData();

	// Public functions
	
	// Watches

	// Private Functions
	function updateCareerStandings() {
		var CareerStandings = $resource('/api/' + $scope.sport + '/results/career');
		var results = CareerStandings.query(function() {
			$scope.standings = results;
		});
	}
});