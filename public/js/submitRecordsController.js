angular.module('aepi-fantasy').controller('SubmitRecordsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var sport = $scope.$parent.getSportType();
	var userMap = {};


	// Public variables
	$scope.sport = capitaliseFirstLetter(sport);
	$scope.types = ['career','season','weekly'];
	$scope.records = getRecords();
	$scope.years = [];
	$scope.record = {
		record_holders:[{}]
	};
	$scope.users = populateUsers();

	initializeYears();

	// Public functions
	$scope.submitRecord = function() {
		$scope.recordMessage = '';
		if(validate($scope.record)) {
			var Record = $resource('/api/' + sport + "/record");
			Record.save($scope.record, function(response) {
				$scope.recordMessage = 'Record Submitted'
				if(response.success) {
					$scope.record = {
						record_holders: [{}]
					}
				}
			});
		} 
	}

	$scope.recordSelected = function(item, model, label) {
		$scope.record = item
		for(var c = 0; c < $scope.record.record_holders.length; c++) {
			$scope.record.record_holders[c].name = userMap[$scope.record.record_holders[c].name]
		}
	}

	$scope.filterRecords = function(actual, expected) {
		if(actual.type == $scope.record.type) {
			return true;
		} else {
			return false;
		}
	}

	$scope.addOwner = function() {
		$scope.record.record_holders.push({});
	}

	$scope.removeOwner = function(index) {
		$scope.record.record_holders.splice(index,1);
	}

	$scope.showOwnerLabel = function(index) {
		return index == 0;
	}

	$scope.showAddOwner = function(index) {
		return index == 0;
	}

	$scope.showRemoveOwner = function(index) {
		return index > 0;
	}

	$scope.getOwnerClass = function(index) {
		if(index > 0) {
			return 'col-sm-offset-2';
		} else {
			return '';
		}
	}


	// Watches
	$scope.$watch('record.type', checkYears);


	// Private Functions
	function checkYears(newValue, oldValue) {
		if(newValue == 'career') {
			$scope.record.years = [];
		}
	}

	function validate(record) {
		var missingFields = false;
		if(!record.value) {
			missingFields = true;
		}
		if(!record.type) {
			missingFields = true;
		}
		if(!record.record) {
			missingFields = true;
		}

		var repeatedOwners = false;
		var owners = [];
		for(var c = 0; c < record.record_holders.length; c++) {
			if(owners.indexOf(record.record_holders[c].name.name) != -1) {
				repeatedOwners = true;
			}
			owners.push(record.record_holders[c].name.name);

			if(!record.record_holders[c].name.name) {
				missingFields = true;
			}
			if(record.type != 'career' && !record.record_holders[c].year) {
				missingFields = true;
			}
		}

		if(missingFields) {
			$scope.recordMessage = 'Missing fields.';
			return false;
		}

		if(repeatedOwners) {
			$scope.recordMessage = 'Cannot have duplicate owners';
			return false;
		}

		return true;
	}

	function getRecords() {
		var Records = $resource('/api/' + sport + '/records');
		var results = Records.query();

		return results;
	}

	function initializeYears() {
		var Years = $resource('/api/' + sport + '/years');
		var results = Years.query(function(response) {
			$scope.years = [];
			for(var c = 0; c < results.length; c++) {
				$scope.years.push(results[c].year.toString());
			}
		});
	}

	function populateUsers() {
		var Users = $resource('/api/allusers/' + sport);
		var results = Users.query(function(response) {
			for(var c = 0; c < results.length; c++) {
				userMap[results[c].name] = results[c];
			}
		})

		return results;
	}

	function capitaliseFirstLetter(str)
	{
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}
});