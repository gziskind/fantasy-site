angular.module('aepi-fantasy').controller('NotificationController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.notifications = getNotifications();
	$scope.notificationMessage = ''

	// Public functions
	$scope.saveNotificationOptions = function() {
		var Notifications = $resource('/api/user/notifications');
		Notifications.save($scope.notifications, function(response) {
			$scope.notificationMessage = response.message;
		});
	}


	// Watches

	// Private Functions
	function getNotifications() {
		var Notifications = $resource('/api/user/notifications');

		var results = Notifications.get();

		return results;
	}
});