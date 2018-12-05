angular.module('aepi-fantasy').controller('AdminLogController', function($scope, $location, $routeParams, $resource) {

    // Private variables
    $scope.logMessages = []
   

    // Public variables
    refreshLog(45,1);

    // Watches

    // Public Functions
    

    // Private Functions
    function refreshLog(count, page) {
		var Log = $resource('/api/admin/log/' + count + '/' + page);
		var results = Log.query(function() {
			$scope.logMessages = results
		});
	}
});