angular.module('aepi-fantasy',['ngRoute','ngResource','ipCookie','ui.sortable','ui.bootstrap','ngImgCrop','checklist-model'], function($routeProvider) {
	$routeProvider.when('/results/overall', {
		controller: 'ResultsController',
		templateUrl: '/pages/results.html'
	});

	$routeProvider.when('/results/:year', {
		controller: 'ResultsController',
		templateUrl: '/pages/resultsYear.html'
	});

	$routeProvider.when('/records/create', {
		controller: 'SubmitRecordsController',
		templateUrl: '/pages/createRecord.html'
	})

	$routeProvider.when('/records/:type', {
		controller: 'RecordsController',
		templateUrl: '/pages/records.html'
	})

	$routeProvider.when('/names', {
		controller: 'NamesController',
		templateUrl: '/pages/currentNames.html'
	})

	$routeProvider.when('/names/:user',{
		controller: 'NamesController',
		templateUrl: '/pages/userNames.html'
	})

	$routeProvider.when('/polls/:pollId',{
		controller: 'PollsController',
		templateUrl: '/pages/poll.html'
	})

	$routeProvider.when('/users/current',{
		controller: 'UsersController',
		templateUrl: '/pages/currentUsers.html'
	})

	$routeProvider.when('/users/create',{
		controller: 'UsersController',
		templateUrl: '/pages/createUser.html'
	});

	$routeProvider.when('/profile/:user', {
		controller: 'ProfilesController',
		templateUrl:'/pages/profile.html'
	});

	$routeProvider.when('/admin/results',{
		controller: 'AdminCreateResultsController',
		templateUrl: '/pages/createResults.html'
	});

	$routeProvider.when('/admin/results/:sport',{
		controller: 'AdminResultsController',
		templateUrl: '/pages/editResults.html'
	});

	$routeProvider.when('/admin/records/:sport',{
		controller: 'AdminRecordsController',
		templateUrl: '/pages/confirmRecords.html'
	});

	$routeProvider.when('/admin/events/summary',{
		controller: 'AdminEventsController',
		templateUrl: '/pages/summaryEvents.html'
	});

	$routeProvider.when('/admin/events/live',{
		controller: 'AdminEventsController',
		templateUrl: '/pages/liveEvents.html'
	});	

	$routeProvider.when('/admin/parsing',{
		controller: 'AdminParsingController',
		templateUrl: '/pages/parsing.html'
	});

	$routeProvider.when('/admin/playerMap',{
		controller: 'AdminParsingController',
		templateUrl: '/pages/playerMap.html'
	});
	
	$routeProvider.when('/draft/:year',{
		controller: 'DraftResultsController',
		templateUrl: '/pages/draftResults.html'
	});



	// $routeProvider.otherwise({
	// 	redirectTo: '/home'
	// });
});


angular.module('aepi-fantasy').filter('capitalize', function() {
    return function(input, scope) {
        return input.substring(0,1).toUpperCase()+input.substring(1);
    }
});

