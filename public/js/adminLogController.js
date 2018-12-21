angular.module('aepi-fantasy').controller('AdminLogController', function($scope, $location, $routeParams, $resource) {

    // Private variables
   	var pageSize = 45;

    // Public variables
    $scope.logMessages = []
    $scope.selectedLoggerType = ""

    // Watches
    $scope.$watch('logLevels', logLevelChanged, true);

    // Public Functions
    $scope.selectLogger = function(loggerType) {
    	$scope.selectedLoggerType = loggerType;
    	refreshLog(loggerType, pageSize,1, $scope.logLevels)
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

    $scope.clearLog = function() {
    	if($scope.selectedLoggerType) {
    		var Log = $resource('/api/admin/log/' + $scope.selectedLoggerType)
    		Log.delete(function(response) {
    			if(response.success) {
    				refreshLog($scope.selectedLoggerType, pageSize, 1, $scope.logLevels)
    			}
    			console.info("Deleted" + response.success)
    		})
    	}
    }
    
    $scope.loadMoreLogs = function() {
    	refreshLog($scope.selectedLoggerType, pageSize, 1, $scope.logLevels, true)
    }

    // Private Functions
    function logLevelChanged() {
    	if($scope.selectedLoggerType) {
    		refreshLog($scope.selectedLoggerType, pageSize, 1, $scope.logLevels, true)
    	}
    }

    function refreshLog(type, count, page, levels, append) {
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