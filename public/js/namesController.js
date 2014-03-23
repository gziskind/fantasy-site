angular.module('aepi-fantasy').controller('NamesController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.sport = capitaliseFirstLetter($scope.$parent.getSportType());
	$scope.names = [];
	$scope.user = $routeParams.user;

	// Public functions

	// Watches
	$scope.$watch('user', updateNames)

	// Private Functions
	function updateNames(newValue, oldValue) {
		var url = '';
		var sport = $scope.$parent.getSportType();
		if(newValue) {
			url = '/api/' + sport + '/names/' + newValue;
		} else {
			url = '/api/' + sport + '/names';
		}
		var TeamNames = $resource(url);
		var value = TeamNames.query();

		$scope.names = value;
	}

	function capitaliseFirstLetter(str)
	{
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});