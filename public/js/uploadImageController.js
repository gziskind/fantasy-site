angular.module('aepi-fantasy').controller('UploadImageController', function($scope, $modalInstance, $resource, fileUpload) {

	// Private Variables

	// Public variables
    $scope.myCroppedImage = '';
    $scope.loadingMessage = '';
    $scope.sending = false;

	// Public functions
	$scope.fileUpload = function() {
        var currentSrc = angular.element("#croppedImage")[0].src;
        var base64 = currentSrc.replace("data:image/png;base64,","");

        $scope.sending = true;
        $scope.loadingMessage = "Uploading..."

		fileUpload.uploadFileToUrl(base64, "https://api.imgur.com/3/image/", function(response) {
			if(response.success) {
				var imageLink = response.data.link;

				$modalInstance.close(imageLink.replace(/https?:/,""));
			} else {
                $scope.loadingMessage = "Upload Failed";
                $scope.sending = false;
            }
        }, function() {
            $scope.loadingMessage = "Upload Failed";
            $scope.sending = false;
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
                var file = element[0].files[0]
                var reader = new FileReader();
                reader.onload = function(evt) {
                    scope.$apply(function(){
                        modelSetter(scope.$parent, evt.target.result);
                    });
                };
                reader.readAsDataURL(file)
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

angular.module('aepi-fantasy').directive('clickOnce', function($timeout) {
    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            var replacementText = attrs.clickOnce;

            element.bind('click', function() {
                $timeout(function() {
                    if (replacementText) {
                        element.html(replacementText);
                    }
                    element.attr('disabled', true);
                }, 0);
            });
        }
    };
});