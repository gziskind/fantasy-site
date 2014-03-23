angular.module('aepi-fantasy').controller('PollsController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.pollId = $routeParams.pollId;
	$scope.poll = null;


	// Public functions

	// Watches
	$scope.$watch('pollId', updatePoll)

	// Private Functions
	function updatePoll(newValue, oldValue) {
		var Results = $resource('/api/polls/:pollId')
		var value = Results.get({pollId: newValue});

		$scope.poll = value
	}

	function capitaliseFirstLetter(str) {
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});