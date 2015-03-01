angular.module('aepi-fantasy').controller('UploadImageController', function($scope, $modalInstance, $resource, fileUpload) {

	// Private Variables


	// Public variables


	// Public functions
	$scope.fileUpload = function(testing) {
		fileUpload.uploadFileToUrl($scope.uploadedFile, "https://api.imgur.com/3/image/", function(response) {
			if(response.success) {
				var imageLink = response.data.link;

				$modalInstance.close(imageLink);
			} else {
				console.info("failture");
			}
		});
	}

	$scope.cancel = function() {
		$modalInstance.close();
	}
	// Watches


	// Private Functions
});

angular.module('aepi-fantasy').directive('fileModel', function ($parse) {
    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            var model = $parse(attrs.fileModel);
            var modelSetter = model.assign;
            
            element.bind('change', function(){
                scope.$apply(function(){
                    modelSetter(scope.$parent, element[0].files[0]);
                });
            });
        }
    };
});

angular.module('aepi-fantasy').service('fileUpload', function ($http) {
    this.uploadFileToUrl = function(file, uploadUrl, success, failure){
        var fd = new FormData();
        fd.append('image', file);
        $http.post(uploadUrl, fd, {
            transformRequest: angular.identity,
            headers: {
            	'Content-Type': undefined,
            	'Authorization': 'Client-ID 569f068fc91d6cc'
            }
        })
        .success(success)
        .error(failure);
    }
});