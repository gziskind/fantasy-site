angular.module('aepi-fantasy').controller('ChangePasswordController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.syncedPassword = true;
	$scope.passwordMessage = '';
	$scope.password = {
		password:''
	}

	// Public functions
	$scope.changePassword = function() {
		if($scope.syncedPassword && validate()) {
			var Password = $resource('/api/changePassword');
			Password.save($scope.password, function(response) {
				$scope.passwordMessage = response.message;
				if(response.success) {
					$scope.password = {}
				}
			});
		}
	}

	$scope.confirmPasswordClass = function() {
		if(!$scope.syncedPassword) {
			return "has-warning"
		} else {
			return "";
		}
	}

	// Watches
	$scope.$watch('password.newPassword1', checkPasswordSync);
	$scope.$watch('password.newPassword2', checkPasswordSync);


	// Private Functions
	function validate() {
		if($scope.password.currentPassword && $scope.password.newPassword1 && $scope.password.newPassword2) {
			return true;
		} else {
			$scope.passwordMessage = 'Missing Fields';
		}
	}

	function checkPasswordSync() {
		if($scope.password) {
			if($scope.password.newPassword1 != $scope.password.newPassword2) {
				$scope.syncedPassword = false;
			} else {
				$scope.syncedPassword = true;
			}
		}
	}
});