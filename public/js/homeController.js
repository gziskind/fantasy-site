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

	$scope.currentUser = parseOutPluses(ipCookie(CURRENT_USER));
	if($scope.currentUser) {
		$scope.loginSubmitted = true;
	} else {
		$scope.loginSubmitted = false;
	}

	$scope.alerts = populateAlerts();

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
				var path = getQueryVariable('redirect');
				var hash = document.location.hash;

				if(path) {
					window.location = path + hash;
				} else {
					window.location.reload()
				}
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

	$scope.isActiveAllRecords = function() {
		return activeUrlCompare('records/current');
	}

	$scope.isActiveCareerRecords = function() {
		return activeUrlCompare('records/career');
	}

	$scope.isActiveSeasonRecords = function() {
		return activeUrlCompare('records/season');
	}

	$scope.isActiveWeeklyRecords = function() {
		return activeUrlCompare('records/weekly');
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

	$scope.isActiveProfileUser = function(user) {
		return activeUrlCompare('profile/' + user);
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

	$scope.isAdminCreateResult = function() {
		return activeUrlCompare('admin/results');
	}

	$scope.isAdminSummaryEvents = function() {
		return activeUrlCompare('admin/events/summary');
	}

	$scope.isAdminLiveEvents = function() {
		return activeUrlCompare('admin/events/live');
	}

	$scope.getSportType = function() {
		var path = window.location.pathname;
		if(path.indexOf('football') != -1) {
			return 'football';
		} else {
			return 'baseball';
		}
	}

	$scope.getAlerts = function(alerts) {
		var currentLevel = $scope.alerts;
		for(var c = 0; c < alerts.length; c++) {
			if(currentLevel != null) {
				currentLevel = currentLevel[alerts[c]];
			}
		}

		var count = sumAlertLevel(currentLevel);

		if(count === 0) {
			count = null;
		}

		return count;
	}

	// Private functions
	function sumAlertLevel(currentLevel) {
		if(typeof currentLevel === 'object') {
			var midSum = 0;
			for(level in currentLevel) {
				midSum += sumAlertLevel(currentLevel[level]);
			}
			return midSum;
		} else {
			return currentLevel;
		}
	}

	function populateAlerts() {
		var Alerts = $resource('/api/alerts');
		var alerts = Alerts.get(function(response) {

		});

		return alerts;
	}

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

	
	function getQueryVariable(variable) {
	    var query = window.location.search.substring(1);
	    var vars = query.split('&');
	    for (var i = 0; i < vars.length; i++) {
	        var pair = vars[i].split('=');
	        if (decodeURIComponent(pair[0]) == variable) {
	            return decodeURIComponent(pair[1]);
	        }
	    }
	}

	function parseOutPluses(obj) {
		if(obj) {
			obj.name = obj.name.replace(/[+]/g," ");
		}

		return obj;
	}
})