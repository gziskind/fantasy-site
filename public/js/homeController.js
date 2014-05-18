angular.module('aepi-fantasy').controller('HomeController', function($scope, $location, $resource, $cookieStore) {
	
	$scope.currentUser = $cookieStore.get('currentUser');

	// Public functions
	$scope.signIn = function() {
		var Login = $resource('/api/login');
		Login.save($scope.user, function(response) {
			if(response.error) {
				console.info(response.error);
			} else {
				$scope.currentUser = {
					id: response.id,
					username: response.username
				};

				$cookieStore.put('currentUser', $scope.currentUser);
			}
		})
	}

	$scope.isActiveYear = function(year) {
		var url = extractUrlAfterBang();
		if('results/' + year == url) {
			return 'active'
		} else {
			return ''
		}
	}
	$scope.isActiveRecordsUser = function(user) {
		var url = extractUrlAfterBang();
		if('records/' + user == url) {
			return 'active';
		} else {
			return ''
		}
	}
	$scope.isActiveTeamsUser = function(user) {
		var url = extractUrlAfterBang();
		if('names/' + user == url) {
			return 'active';
		} else {
			return ''
		}
	}

	$scope.isActivePoll = function(pollId) {
		var url = extractUrlAfterBang();
		if('polls/' + pollId == url) {
			return 'active'
		} else {
			return ''
		}
	}

	$scope.getSportType = function() {
		var path = window.location.pathname;
		if(path.indexOf('football') != -1) {
			return 'football';
		} else {
			return 'baseball';
		}
	}


	// Private functions
	function extractUrlAfterBang() {
		return $location.url().substr(1);
	}
})