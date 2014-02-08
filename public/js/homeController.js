angular.module('aepi-fantasy').controller('HomeController', function($scope, $location) {
	
	// Public functions
	$scope.changeToBaseball = function() {
		changePage('/baseball')
	}

	$scope.changeToFootball = function() {
		changePage('/football')
	}

	$scope.isHomeActive = function() {
		return isActive('/home')
	}

	$scope.isBaseballActive = function() {
		return isActive('/baseball')
	}

	$scope.isFootballActive = function() {
		return isActive('/football')
	}


	// Private functions
	function changePage(page) {
		$location.path(page);
	}

	function isActive(page) {
		if($location.path() == page) {
			return "active"
		} else {
			return ""
		}
	}
})