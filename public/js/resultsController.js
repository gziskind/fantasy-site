angular.module('aepi-fantasy').controller('ResultsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.year = $routeParams.year;
	$scope.results = []
	$scope.leagueName = '';
	$scope.currentYear = new Date().getFullYear();
	$scope.selectedStandingsType = 'final';

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
	$scope.$watch('selectedStandingsType', updateStandingsOrder);

	// Private Functions
	function updateResults(newValue, oldValue) {
		var sport = $scope.$parent.getSportType()
		var Season = $resource('/api/' + sport + '/results/:year')
		var value = Season.get({year: newValue}, function(){
			if(value.length > 0) {
				firstPlaceNumber = value[0].wins - value[0].losses
			}

			$scope.leagueName = value.leagueName;
			$scope.results = value.results;
		});
	}

	function updateStandingsOrder(newValue, oldValue) {
		$scope.results = sortByStandingsType($scope.results);
	}

	function sortByStandingsType(results) {
		if($scope.selectedStandingsType == 'final') {
			return sortByPlace(results);
		} else {
			return sortByRegularSeason(results);
		}

		return finalResults;
	}

	function sortByPlace(results) {
		results.sort(function(result1, result2) {
			if(result1.place < result2.place) {
				return -1;
			} else {
				return 1;
			}
		});

		return results;
	}

	function sortByRegularSeason(results) {
		for(var c = 0; c < results.length; c++) {
			results[c].winPercentage = calculateWinPercentage(results[c]);
		}

		results.sort(function(result1, result2) {
			if(result1.winPercentage < result2.winPercentage) {
				return 1;
			} else if(result1.winPercentage > result2.winPercentage) {
				return -1;
			} else {
				if(result1.points && result2.points) {
					if(result1.points < result2.points) {
						return 1;
					} else {
						return -1;
					}
				} else {
					return 0;
				}
			}
		});

		return results;
	}

	function calculateWinPercentage(result) {
		return (result.wins + (result.ties/2.0))/(result.wins + result.losses + result.ties + 1.0);
	}
});