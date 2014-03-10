angular.module('aepi-fantasy').controller('HomeController', function($scope, $location) {
	
	// Public functions
	$scope.isActiveYear = function(year) {
		var url = extractUrlAfterBang();
		if('results/' + year == url) {
			return 'active'
		} else {
			return ''
		}
	}
	$scope.isActiveUser = function(user) {
		var url = extractUrlAfterBang();
		if('records/' + user == url) {
			return 'active';
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