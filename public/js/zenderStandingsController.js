angular.module('aepi-fantasy').controller('ZenderStandingsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var firstPlaceNumber = 0;

	// Public variables
	$scope.contentLoaded = false;
	$scope.winValue = 2;
	$scope.pointsValue = 1;

	getStandings();

	// updateRotoData();

	// Public functions
	$scope.getGamesBack = function(result) {
		var resultNumber = result.wins - result.losses;

		if(resultNumber == firstPlaceNumber) {
			return '-'
		} else {
			return (firstPlaceNumber - resultNumber) / 2
		}
	}

	$scope.decrementWinValue = function() {
		if($scope.winValue > 0) {
			$scope.winValue--;
		}
	}

	$scope.incrementWinValue = function() {
		if($scope.winValue < 99) {
			$scope.winValue++;
		}
	}

	$scope.decrementPointsValue = function() {
		if($scope.pointsValue) {
			$scope.pointsValue--;
		}
	}

	$scope.incrementPointsValue = function() {
		if($scope.pointsValue < 99) {
			$scope.pointsValue++;
		}
	}
	
	// Watches
	$scope.$watch("winValue", getZenderStandings);
	$scope.$watch('pointsValue', getZenderStandings);

	// Private Functions
	function getZenderStandings() {
		$scope.standings = [];
		for(name in $scope.zenderResults) {
			var result = $scope.zenderResults[name]
			if(result.wins) {
				wins = result.wins * $scope.winValue + result.points_wins * $scope.pointsValue;
				losses = result.losses * $scope.winValue + result.points_losses * $scope.pointsValue;

				winPercentage = Math.round((wins / ((wins + losses)*1.0)) * 1000)/1000

				var standing = {
					owner: name,
					name: result.team_name,
					wins: wins,
					losses: losses,
					winPercentage: winPercentage,
					points: result.points
				};

				$scope.standings.push(standing);

				var newFirstPlaceNumber = result.wins - result.losses;
				if(newFirstPlaceNumber > firstPlaceNumber) {
					firstPlaceNumber = newFirstPlaceNumber;
				}
			}
		}

		$scope.standings.sort(function(standing1, standing2) {
			if(standing1.winPercentage == standing2.winPercentage) {
				return standing2.points - standing1.points;
			} else {
				return standing2.winPercentage - standing1.winPercentage;
			}
		})
	}

	function getStandings() {
		var ZenderStandings = $resource('/api/football/results/current');
		var result = ZenderStandings.get(function() {
			$scope.zenderResults= result;

			getZenderStandings();
			
			$scope.contentLoaded = true;
		});
	}
});