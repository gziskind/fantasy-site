angular.module('aepi-fantasy').controller('ResultsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.year = $routeParams.year;
	$scope.results = []

	// Watches
	$scope.$watch('year', updateResults);

	// Private Functions
	function updateResults(newValue, oldValue) {
		var sport = $scope.$parent.getSportType()
		var Results = $resource('/api/' + sport + '/results/:year')
		var value = Results.query({year: newValue});

		$scope.results = value
	}
});