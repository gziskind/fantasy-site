angular.module('aepi-fantasy').controller('RecordsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.sport = capitaliseFirstLetter($scope.$parent.getSportType());
	$scope.records = [];
	$scope.user = $routeParams.user;


	// Public functions

	// Watches
	$scope.$watch('user', updateRecords)

	// Private Functions
	function updateRecords(newValue, oldValue) {
		var url = '';
		var sport = $scope.$parent.getSportType();
		if(newValue) {
			url = '/api/' + sport + '/records/' + newValue;
		} else {
			url = '/api/' + sport + '/records';
		}
		var Records = $resource(url);
		var value = Records.query();

		$scope.records = value;
	}

	function capitaliseFirstLetter(str)
	{
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});