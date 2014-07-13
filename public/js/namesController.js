angular.module('aepi-fantasy').controller('NamesController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var sport = $scope.$parent.getSportType();

	// Public variables
	$scope.sport = capitaliseFirstLetter(sport);
	$scope.names = [];
	$scope.user = $routeParams.user;

	initializeYears();

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

	$scope.submitTeamName = function() {
		$scope.teamMessage = '';
		if(validate($scope.name)) {
			var TeamName = $resource('/api/' + sport + "/names/" + $scope.currentUser.name);
			TeamName.save($scope.name, function(response) {
				if(response.success) {
					$scope.teamMessage = 'Team Name Submitted';
					$scope.names.push($scope.name);
					$scope.name = {};
				} else {
					$scope.teamMessage = response.message;
				}
			});
		} 
	}


	// Private Functions
	function validate(name) {
		if(name.teamName && name.year) {
			return true;
		} else {
			return false;
		}
	}

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

	function initializeYears() {
		var Years = $resource('/api/' + sport + '/years');
		var results = Years.query(function(response) {
			$scope.years = [];
			for(var c = 0; c < results.length; c++) {
				$scope.years.push(results[c].year);
			}
		});
	}

	function reloadNames(newValue, oldValue) {
		updateNames($scope.user);
	}

	function capitaliseFirstLetter(str) {
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});