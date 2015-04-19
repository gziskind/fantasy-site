angular.module('aepi-fantasy').controller('LandingController', function($scope, $location, $routeParams, $resource) {

	// Private Variables


	// Public variables
	$scope.contentLoaded = false;

	updateLandingData();


	// Public functions
	
	// Watches


	// Private Functions
	$scope.changeRating = function(name) {
		if(name.previousRating != name.myRating) {
			name.previousRating = name.myRating
			
			var Rating = $resource('/api/' + name.sport + '/names/rating');
			Rating.save(name, function(response) {
				name.rating = response.totalRating
			});
		}
	}

	function updateLandingData() {
		var Landing = $resource('/api/landing');
		var results = Landing.get(function() {
			$scope.championships = results.championships;
			$scope.lastPlaces = results.lastPlaces;
			$scope.bestTeamNames = results.bestTeamNames;
			$scope.worstTeamNames = results.worstTeamNames;
			$scope.newRecords = results.newRecords;

			$scope.newTeamNames = results.newTeamNames;
			for(var c = 0; c < $scope.newTeamNames.length; c++) {
				$scope.newTeamNames[c].previousRating = $scope.newTeamNames[c].myRating;
			}

			$scope.contentLoaded = true;
		})
	}
});