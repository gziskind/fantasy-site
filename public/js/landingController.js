angular.module('aepi-fantasy').controller('LandingController', function($scope, $location, $routeParams, $resource) {

	// Private Variables


	// Public variables
	$scope.contentLoaded = false;

	updateLandingData();


	// Public functions
	
	// Watches


	// Private Functions
	function updateLandingData() {
		var Landing = $resource('/api/landing');
		var results = Landing.get(function() {
			$scope.championships = results.championships;
			$scope.lastPlaces = results.lastPlaces;
			$scope.bestTeamNames = results.bestTeamNames;
			$scope.worstTeamNames = results.worstTeamNames;
			$scope.newTeamNames = results.newTeamNames;
			$scope.newRecords = results.newRecords;

			$scope.contentLoaded = true;
		})
	}
});