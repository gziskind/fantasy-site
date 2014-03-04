angular.module('aepi-fantasy').controller('HomeController', function($scope, $location) {
	
	// Public functions
	$scope.isActive = function(year) {
		var url = extractUrlAfterBang();
		if(year == url) {
			return 'active'
		} else {
			return ''
		}
	}

	// Private functions
	function extractUrlAfterBang() {
		return $location.url().substr(1);
	}
})