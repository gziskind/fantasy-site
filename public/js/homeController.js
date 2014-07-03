angular.module('aepi-fantasy').controller('HomeController', function($scope, $location, $resource, ipCookie) {
	var CURRENT_USER = "currentUser";

	$scope.$watch('validUser', function () {
		if(!$scope.validUser) {
			ipCookie.remove(CURRENT_USER, {path:'/'});
			$scope.currentUser = false;
			$scope.loginSubmitted = false;
			$scope.loginFailed = false;
		}
	});

	$scope.currentUser = ipCookie(CURRENT_USER);
	if($scope.currentUser) {
		$scope.loginSubmitted = true;
	} else {
		$scope.loginSubmitted = false;
	}

	// Public functions
	$scope.isAdmin = function() {
		var admin = false;
		if($scope.currentUser) {
			for(var c = 0; c < $scope.currentUser.roles.length; c++) {
				if($scope.currentUser.roles[c].name == 'admin') {
					admin = true;
				}
			}
		}

		return admin;
	}

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
					username: response.username,
					roles: response.roles
				};

				ipCookie(CURRENT_USER, $scope.currentUser, {path: '/'})
			}
		})
	}

	$scope.logout = function() {
		ipCookie.remove(CURRENT_USER, {path:'/'});
		$scope.currentUser = false;
		$scope.loginSubmitted = false;
		$scope.loginFailed = false;

		var Logout = $resource('/api/logout');
		Logout.save();
	}

	$scope.isActiveYear = function(year) {
		return activeUrlCompare('results/' + year);
	}

	$scope.isActiveRecords = function() {
		return activeUrlCompare('records/current');
	}

	$scope.isActiveCreateRecord = function() {
		return activeUrlCompare('records/create');
	}

	$scope.isActiveTeamsUser = function(user) {
		return activeUrlCompare('names/' + user);
	}

	$scope.isActiveCurrentTeams = function() {
		return activeUrlCompare('names');
	}

	$scope.isActivePoll = function(pollId) {
		return activeUrlCompare('polls/' + pollId);
	}

	$scope.isAdminCurrentUsers = function() {
		return activeUrlCompare('users/current');
	}

	$scope.isAdminCreateUser = function() {
		return activeUrlCompare('users/create');
	}

	$scope.isAdminBaseballResults = function() {
		return activeUrlCompare('admin/results/baseball');
	}

	$scope.isAdminFootballResults = function() {
		return activeUrlCompare('admin/results/football');
	}

	$scope.isAdminBaseballRecords = function() {
		return activeUrlCompare('admin/records/baseball');
	}

	$scope.isAdminFootballRecords = function() {
		return activeUrlCompare('admin/records/football');
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
	function activeUrlCompare(url) {
		var extracted_url = extractUrlAfterBang();
		if(url == extracted_url) {
			return "active"
		} else {
			return ''
		}
	}

	function extractUrlAfterBang() {
		return $location.url().substr(1).replace(/%20/g,' ');
	}
})