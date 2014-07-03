angular.module('aepi-fantasy').controller('AdminRecordsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var sport = $routeParams.sport;

	// Public variables
	$scope.sport = capitaliseFirstLetter(sport);
	$scope.records = getUnconfirmedRecords();

	// Watches

	// Public Functions
	$scope.confirmRecord = function(record) {
		record.submitted = true;
		var Record = $resource('/api/admin/' + sport + '/record/confirm');
		Record.save(record, function(response) {
			if(response.success) {
				record.confirmed = true
			}
		});
	}


	// Private Functions
	function getUnconfirmedRecords() {
		var Records = $resource('/api/admin/' + sport + '/records');
		var results = Records.query({confirmed: false}, function(response) {
			for(var c = 0; c < results.length; c++) {
				results[c].submitted = false;
			}
		});

		return results;
	}

	function capitaliseFirstLetter(str) {
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});