angular.module('aepi-fantasy').controller('RecordsController', function($scope, $location, $routeParams, $resource) {

	// Private Variables
	var sport = $scope.$parent.getSportType();
	var userMap = {};


	// Public variables
	$scope.sport = capitaliseFirstLetter(sport);
	$scope.records = [];
	$scope.users = populateUsers();
	$scope.user = $routeParams.user;
	$scope.record = {
		owners: [{}]
	};


	// Public functions
	$scope.submitRecord = function() {
		$scope.recordMessage = '';
		if(validate($scope.record)) {
			var Record = $resource('/api/' + sport + "/record");
			Record.save($scope.record, function(response) {
				$scope.recordMessage = 'Record Submitted'
				if(response.success) {
					$scope.record = {
						owners: [{}]
					}
				}
			});
		} 
	}

	$scope.recordSelected = function(item, model, label) {
		console.info("Selected " + item.record);
		$scope.record = item

		for(var c = 0; c < $scope.record.owners.length; c++) {
			$scope.record.owners[c] = userMap[$scope.record.owners[c].name]
		}
	}

	$scope.addOwner = function() {
		$scope.record.owners.push({});
	}

	$scope.removeOwner = function(index) {
		$scope.record.owners.splice(index,1);
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
	$scope.$watch('user', updateRecords)


	// Private Functions
	function validate(record) {
		if(record.value && record.year && record.record && record.owners[0].name) {
			var owners = [];
			var repeatedOwners = false;
			for(var c = 0; c < record.owners.length; c++) {
				if(owners.indexOf(record.owners[c].name) != -1) {
					repeatedOwners = true;
				}
				owners.push(record.owners[c].name);
			}

			if(repeatedOwners) {
				$scope.recordMessage = 'Cannot have duplicate owners';
			}
			return !repeatedOwners;
		} else {
			$scope.recordMessage = 'Missing fields.';
			return false;
		}
	}

	function updateRecords(newValue, oldValue) {
		var Records = $resource('/api/' + sport + '/records');
		var value = Records.query(function(response) {
			$scope.records = value;
		});
	}

	function populateUsers() {
		var Users = $resource('/api/' + sport + '/allusers');
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