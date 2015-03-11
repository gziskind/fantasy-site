angular.module('aepi-fantasy').controller('UsersController', function($scope, $location, $routeParams, $resource) {

	// Public variables
	$scope.users = getUsers();
	$scope.roles = getRoles();
	$scope.userMessage = '';
	$scope.user = {
		roles:{}
	}

	// Watches
	$scope.$watch('user.password1', checkPasswordSync);
	$scope.$watch('user.password2', checkPasswordSync);


	// Public Functions
	$scope.resetPassword = function(user) {
		user.submitted = true;
		var Password = $resource('/api/admin/users/'+ user.username + '/passwordreset');
		Password.save(function(response) {
			user.confirmed = true;
		})
	}

	$scope.confirmNewPasswordClass = function() {
		if(!$scope.syncedPassword) {
			return "has-warning"
		} else {
			return "";
		}
	}

	$scope.createUser = function() {
		if($scope.syncedPassword) {
			var User = $resource('/api/admin/user');
			User.save($scope.user, function(response) {
				$scope.userMessage = 'User Created.'
				$scope.user = {
					roles:{}
				}
			})
		}
	}


	// Private Functions
	function checkPasswordSync() {
		if($scope.user) {
			if($scope.user.password1 != $scope.user.password2) {
				$scope.syncedPassword = false;
			} else {
				$scope.syncedPassword = true;
			}
		}
	}

	function getUsers() {
		var User = $resource('/api/admin/users')
		var results = User.query();

		return results;
	}

	function getRoles() {
		var Role = $resource('/api/admin/roles');
		var results = Role.query();

		return results;
	}
});