angular.module('aepi-fantasy').controller('AdminResultsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.sport = capitaliseFirstLetter($routeParams.sport);
	$scope.seasons = getSeasons();
	$scope.seasonMessage = '';

	// Watches

	// Public Functions
	$scope.submitSeason = function() {
		for(var c = 1; c <= $scope.season.results.length; c++) {
			$scope.season.results[c-1].place = c;
		}

		var Season = $resource('/api/admin/results');
		Season.save($scope.season, function(response) {
			$scope.seasonMessage = response.message;
		});
	}

	// Private Functions
	function getSeasons() {
		var Seasons = $resource('/api/' + $routeParams.sport + '/results/')
		var value = Seasons.query(function() {
			$scope.seasons = value
			$scope.season = value[0]
			$scope.results = value[0].results;
		});
	}

	function capitaliseFirstLetter(str) {
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});