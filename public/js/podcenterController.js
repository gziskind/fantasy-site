angular.module('aepi-fantasy').controller('PodcenterController', function($scope, $location, $routeParams, $resource, $modal) {

	// Private Variables

	// Public variables

	// Public functions
	$scope.addPodcast = function() {
		var podcastModal = $modal.open({
			templateUrl: 'pages/addPodcast.html',
			windowClass: 'upload-modal',
			controller: function($scope, $modalInstance, audioUpload) {
				$scope.podcast = {};
				$scope.podcastMessage = '';

				$scope.uploadPodcast = function() {
					if(!$scope.podcast.name) {
						$scope.podcastMessage = 'Name Required'
					} else if(!$scope.audioFile) {
						$scope.podcastMessage = 'Podcast File Required';
					} else {
						$scope.podcastMessage = 'Uploading';
						audioUpload.uploadFileToUrl($scope.audioFile, $scope.podcast.name, '/api/podcenter', function(response) {
							$scope.podcastMessage = 'Complete';
							$modalInstance.close({
								url: response.url,
								name: $scope.name
							});
						}, function(response) {
							$scope.podcastMessage = 'Upload Failed';
						});
					}

				}

				$scope.cancel = function() {
					$modalInstance.close();
				}
			}
		});

		podcastModal.result.then(function(podcast) {
			if(podcast) {
				window.location.reload();
			}
		})
	}

	$scope.openPodcast = function(name) {
		var Podcast = $resource('/api/podcenter/' + name);
		Podcast.get(function(response) {
            var userAgent = window.navigator.userAgent.toLowerCase();
            if(userAgent.indexOf("safari") != -1 && userAgent.indexOf("chrome") == -1) {
			    window.location = response.url;
            } else {
                window.open(response.url);
            }
		});
	}

	// Watches


	// Private Functions
});

angular.module('aepi-fantasy').directive('audioFile', function ($parse) {
    return {
        restrict: 'A',
        link: function(scope, element, attrs) {
            var model = $parse(attrs.audioFile);
            var modelSetter = model.assign;
            
            element.bind('change', function(){
                var file = element[0].files[0]
                scope.$apply(function(){
                    modelSetter(scope.$parent, element[0].files[0]);
                });
            });
        }
    };
});


angular.module('aepi-fantasy').service('audioUpload', function ($http) {
    this.uploadFileToUrl = function(file, name, uploadUrl, success, failure){
    	console.info("name = " + name);
        var fd = new FormData();
        fd.append('name', name);
        fd.append('file', file);
        $http.post(uploadUrl, fd, {
            transformRequest: angular.identity,
            headers: { 'Content-Type': undefined }
        })
        .success(success)
        .error(failure);
    }
});
