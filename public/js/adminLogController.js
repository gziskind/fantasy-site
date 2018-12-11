angular.module('aepi-fantasy').controller('AdminLogController', function($scope, $location, $routeParams, $resource) {

    // Private variables
    $scope.logMessages = []
   

    // Public variables
    $scope.selectedLoggerType = ""

    // Watches

    // Public Functions
    $scope.selectLogger = function(loggerType) {
    	$scope.selectedLoggerType = loggerType;
    	refreshLog(loggerType, 45,1)
    }

    $scope.isLoggerSelected = function(loggerType) {
    	if(loggerType == $scope.selectedLoggerType) {
    		return "active"
    	} else {
    		return "";
    	}
    }
    

    // Private Functions
    function refreshLog(type, count, page) {
		var Log = $resource('/api/admin/log/' + type + '/'+ count + '/' + page);
		var results = Log.query(function() {
			$scope.logMessages = results
		});
	}
});