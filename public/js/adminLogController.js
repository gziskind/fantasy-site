angular.module('aepi-fantasy').controller('AdminLogController', function($scope, $location, $routeParams, $resource) {

    // Private variables
    $scope.logMessages = []
   

    // Public variables
    $scope.selectedLoggerType = ""

    // Watches
    $scope.$watch('logLevels', logLevelChanged, true);

    // Public Functions
    $scope.selectLogger = function(loggerType) {
    	$scope.selectedLoggerType = loggerType;
    	refreshLog(loggerType, 45,1, $scope.logLevels)
    }

    $scope.isLoggerSelected = function(loggerType) {
    	if(loggerType == $scope.selectedLoggerType) {
    		return "active"
    	} else {
    		return "";
    	}
    }

    $scope.getId = function(last) {
    	if(last) {
    		return "bottom-log"
    	} else {
    		return ""
    	}
    }
    

    // Private Functions
    function logLevelChanged() {
    	if($scope.selectedLoggerType) {
    		refreshLog($scope.selectedLoggerType, 45, 1, $scope.logLevels)
    	}
    }

    function refreshLog(type, count, page, levels) {
		var Log = $resource('/api/admin/log/' + type + '/'+ count + '/' + page, {}, {
			getAll: {
				method: 'post', 
				isArray: true
			}
		});

		var results = Log.getAll(levels,function() {
			$scope.logMessages = results
		});
	}
});