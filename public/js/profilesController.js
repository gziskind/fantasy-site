angular.module('aepi-fantasy').controller('ProfilesController', function($scope, $location, $routeParams, $resource, $modal) {

	// Private Variables

	// Public variables
	$scope.contentLoaded = false;
	$scope.user = $routeParams.user;
	$scope.profile = getProfile();
	$scope.sportOptions = [];
	$scope.trophies = [];
	$scope.finishes = [];
	$scope.selectedSport = ''; 
	$scope.bestTeamNames = [];
	$scope.worstTeamNames = [];
	$scope.records = [];

	// Public functions
	$scope.capitaliseFirstLetter = function(str) {
	    return str.charAt(0).toUpperCase() + str.slice(1);
	}

	$scope.transformPlace = function(place) {
		if(place == 1) {
			return '1st';
		} else if(place == 2) {
			return '2nd';
		} else if(place == 3) {
			return '3rd';
		} else {
			return place + 'th';
		}
	}

	$scope.editImage = function() {
		var editImageModal = $modal.open({
			templateUrl: 'pages/uploadImage.html',
		    controller: 'UploadImageController',
		    windowClass: 'upload-modal'
		});

		editImageModal.result.then(function(url) {
			if(url) {
				$scope.profile.imageUrl = url;

				var ImageUrl = $resource("/api/profiles/:user/image", {user:$scope.user});
				ImageUrl.save({imageUrl:url});
			}
		})
	}

	$scope.removeImage = function() {
		var ImageUrl = $resource("/api/profiles/:user/image", {user:$scope.user});
		ImageUrl.delete(function(response) {
			if(response.success) {
				$scope.profile.imageUrl = response.imageUrl;
			}
		});
	}

	// Watches
	$scope.$watch('selectedSport', updateProfile);


	// Private Functions
	function getProfile() {
		var Profile = $resource('/api/profiles/:user');
		var profile = Profile.get({user: $scope.user}, function() {
			$scope.profile = profile;
			$scope.contentLoaded = true;

			setSportOptions();
		});
	}

	function updateProfile(newValue, oldValue) {
		if(newValue) {
			setTrophies();
			setFinishes();
			setTeamNames();
			setRecords();
		}
	}

	function setTrophies() {
		var trophies = [];
		var results = $scope.profile.results;

		for(var c = 0; c < results.length; c++) {
			if(results[c].place <= 3  && isSportSelected(results[c].sport) && results[c].finalized) {
				trophies.push({
					sport: results[c].sport,
					year: results[c].year,
					place: results[c].place
				});
			}
		}

		$scope.trophies = trophies;
	}

	function setFinishes() {
		var finishes = [];
		var results = $scope.profile.results;

		for(var c = 0; c < results.length; c++) {
			if(isSportSelected(results[c].sport) && results[c].finalized) {
				finishes.push(results[c]);
				
				if(results[c].sport == 'baseball') {
					results[c].points = '-';
				}
			}
		}
		$scope.finishes = finishes
	}

	function setSportOptions() {
		var options = [];

		if($scope.profile.roles.indexOf('football') != -1) {
			options.push('football');
		}
		if($scope.profile.roles.indexOf('baseball') != -1) {
			options.push('baseball');
		}

		if(options.length > 1) {
			options.unshift('all');
		}

		$scope.sportOptions = options;
		$scope.selectedSport = options[0];
	}

	function setTeamNames() {
		var bestTeamNames = [];
		var worstTeamNames = [];
		var teamNames = $scope.profile.team_names;

		for(var c = 0; c < teamNames.length; c++) {
			if(isSportSelected(teamNames[c].sport)) {
				if(teamNames[c].rating > 2.5) {
					bestTeamNames.push(teamNames[c]);
				} else if(teamNames[c].rating > 0 && teamNames[c].rating <= 2.5) {
					worstTeamNames.push(teamNames[c]);
				}
			}
		}

		$scope.bestTeamNames = filterTeamNames(bestTeamNames, false, 5);
		$scope.worstTeamNames = filterTeamNames(worstTeamNames, true, 5);
	}

	function filterTeamNames(teams, reverse, size) {
		teams.sort(function(team1, team2) {
			if(team1.rating < team2.rating) {
				return reverse ? -1 : 1;
			} else {
				return reverse ? 1 : -1;
			}
		});

		return teams.slice(0, size);
	}

	function setRecords() {
		var records = [];
		var allRecords = $scope.profile.records;

		for(var c = 0; c < allRecords.length; c++) {
			if(isSportSelected(allRecords[c].sport)) {
				records.push(allRecords[c]);
			}
		}
		$scope.records = records
	}

	function isSportSelected(sport) {
		if($scope.selectedSport == 'all') {
			return true
		} else {
			return $scope.selectedSport == sport;
		}
	}

	
});