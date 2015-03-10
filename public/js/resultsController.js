angular.module('aepi-fantasy').controller('ResultsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.year = $routeParams.year;
	$scope.results = []
	$scope.leagueName = '';
	$scope.currentYear = new Date().getFullYear();

	// Private Variables
	var firstPlaceNumber = 0;

	// Public Functions
	$scope.getGamesBack = function(result) {
		var resultNumber = result.wins - result.losses;

		if(resultNumber == firstPlaceNumber) {
			return '-'
		} else {
			return (firstPlaceNumber - resultNumber) / 2
		}
	}

	// Watches
	$scope.$watch('year', updateResults);

	// Private Functions
	function updateResults(newValue, oldValue) {
		var sport = $scope.$parent.getSportType()
		var Season = $resource('/api/' + sport + '/results/:year')
		var value = Season.get({year: newValue}, function(){
			if(value.length > 0) {
				firstPlaceNumber = value[0].wins - value[0].losses
			}

			$scope.leagueName = value.leagueName;
			$scope.results = value.results
		});
	}
});