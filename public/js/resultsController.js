angular.module('aepi-fantasy').controller('ResultsController', function($scope, $location, $routeParams, $resource) {
	$scope.year = $routeParams.year;

	$scope.results = []


	$scope.$watch($scope.year, updateResults)

	// Private Functions
	function updateResults(newValue, oldValue) {
		var Results = $resource('/api/results/:year')
		var value = Results.query({year: newValue});

		$scope.results = value
	}
});