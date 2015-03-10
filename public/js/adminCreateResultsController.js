angular.module('aepi-fantasy').controller('AdminCreateResultsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.sports = ['Baseball','Football'];
	$scope.users = populateUsers();
	$scope.season = {
		results:[]
	};

	// Watches

	// Public Functions
	$scope.createSeason = function() {
		var Season = $resource('/api/:sport/results/:year', {sport: $scope.season.sport.toLowerCase(), year: $scope.season.year});
		Season.save($scope.season, function(response) {
			console.info(response);
		});

		$scope.season = {
			results:[]
		};
	}

	$scope.addNewTeam = function() {
		$scope.season.results.push({
			teamName: $scope.team.teamName,
			owner: $scope.team.user.name,
			wins: $scope.team.wins,
			losses: $scope.team.losses,
			ties: $scope.team.ties,
			points: $scope.team.points
		})

		for(var c = 1; c <= $scope.season.results.length; c++) {
			$scope.season.results[c-1].place = c;
		}

		$scope.team = {};
	}

	$scope.filterBySport = function(item) {
		if($scope.season && $scope.season.sport && item.roles.indexOf($scope.season.sport.toLowerCase()) != -1) {
			return true
		} else {
			return false
		}
	}

	// Private Functions
	function populateUsers() {
		var Users = $resource('/api/allusers');
		var results = Users.query();

		return results;
	}
});