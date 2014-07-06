angular.module('aepi-fantasy').controller('RecordsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var sport = $scope.$parent.getSportType();


	// Public variables
	$scope.sport = capitaliseFirstLetter(sport);
	$scope.records = getRecords();
	$scope.type = capitaliseFirstLetter($routeParams.type);


	// Public functions
	$scope.compareType = function(actual, expected) {
		if(actual.toLowerCase() == expected.toLowerCase()) {
			return true;
		} else if(expected == 'Current') {
			return true;
		} else {
			return false;
		}
	}

	// Watches


	// Private Functions
	function getRecords() {
		var Records = $resource('/api/' + sport + '/records');
		var results = Records.query();

		return results;
	}

	function capitaliseFirstLetter(str)
	{
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});