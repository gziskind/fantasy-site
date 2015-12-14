angular.module('aepi-fantasy').controller('CareerStandingsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var firstPlaceNumber = 0;

	// Public variables
	$scope.contentLoaded = false;
	$scope.sport = $scope.$parent.getSportType()

	updateCareerStandings();

	// updateRotoData();

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

	$scope.getGamesBack = function(result) {
		var resultNumber = result.wins - result.losses;

		if(resultNumber == firstPlaceNumber) {
			return '-'
		} else {
			return (firstPlaceNumber - resultNumber) / 2
		}
	}
	
	// Watches

	// Private Functions
	function updateCareerStandings() {
		var CareerStandings = $resource('/api/' + $scope.sport + '/results/career');
		var result = CareerStandings.get(function() {
			$scope.standings = [];
			for(name in result) {
				if(result[name].wins) {
					var standing = {
						name: name,
						wins: result[name].wins,
						losses: result[name].losses,
						ties: result[name].ties,
						winPercentage: result[name].winPercentage,
						points: result[name].points
					};

					$scope.standings.push(standing);

					var newFirstPlaceNumber = result[name].wins - result[name].losses;
					if(newFirstPlaceNumber > firstPlaceNumber) {
						firstPlaceNumber = newFirstPlaceNumber;
					}
				}
			}

			$scope.orderByField = 'winPercentage';
			if($scope.sport == 'football') {
				$scope.orderByField = 'points';
			}
			$scope.reverseSort = true;
			$scope.contentLoaded = true;
		});
	}
});