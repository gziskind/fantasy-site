angular.module('aepi-fantasy').controller('HomeController', function($scope, $location, $resource, $cookieStore) {
	var CURRENT_USER = "currentUser";

	$scope.$watch('validUser', function () {
		if(!$scope.validUser) {
			$cookieStore.remove(CURRENT_USER);
			$scope.currentUser = false;
			$scope.loginSubmitted = false;
			$scope.loginFailed = false;
		}
	});

	$scope.currentUser = $cookieStore.get(CURRENT_USER);
	if($scope.currentUser) {
		$scope.loginSubmitted = true;
	} else {
		$scope.loginSubmitted = false;
	}

	// Public functions
	$scope.signIn = function() {
		$scope.loginSubmitted = true;
		$scope.loginFailed = false;
		var Login = $resource('/api/login');
		Login.save($scope.user, function(response) {
			if(response.error) {
				$scope.loginFailed = true;
				$scope.loginSubmitted = false;
			} else {
				$scope.currentUser = {
					id: response.id,
					username: response.username
				};

				$cookieStore.put(CURRENT_USER, $scope.currentUser);
			}
		})
	}

	$scope.logout = function() {
		$cookieStore.remove(CURRENT_USER);
		$scope.currentUser = false;
		$scope.loginSubmitted = false;
		$scope.loginFailed = false;

		var Logout = $resource('/api/logout');
		Logout.save();
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