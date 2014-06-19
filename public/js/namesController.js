angular.module('aepi-fantasy').controller('NamesController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var sport = $scope.$parent.getSportType();

	// Public variables
	$scope.sport = capitaliseFirstLetter(sport);
	$scope.names = [];
	$scope.user = $routeParams.user;

	// Watches
	$scope.$watch('user', updateNames)
	$scope.$watch('currentUser', reloadNames)
	
	// Public functions
	$scope.changeRating = function(name) {
		if(name.previousRating != name.myRating) {
			name.previousRating = name.myRating
			
			var Rating = $resource('/api/' + sport + '/names/rating');
			Rating.save(name, function(response) {
				name.rating = response.totalRating
			});
		}
	}


	// Private Functions
	function updateNames(newValue, oldValue) {
		var url = '';
		if(newValue) {
			url = '/api/' + sport + '/names/' + newValue;
		} else {
			url = '/api/' + sport + '/names';
		}
		
		var TeamNames = $resource(url);
		var value = TeamNames.query(function(response) {
			for(var c = 0; c < value.length; c++) {
				value[c].previousRating = value[c].myRating
			}
			$scope.names = value;
		});
	}

	function reloadNames(newValue, oldValue) {
		updateNames($scope.user);
	}

	function capitaliseFirstLetter(str) {
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});