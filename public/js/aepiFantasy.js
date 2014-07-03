angular.module('aepi-fantasy',['ngRoute','ngResource','ipCookie','ui.sortable','ui.bootstrap'], function($routeProvider) {
	$routeProvider.when('/results/overall', {
		controller: 'ResultsController',
		templateUrl: '/pages/results.html'
	});

	$routeProvider.when('/results/:year', {
		controller: 'ResultsController',
		templateUrl: '/pages/resultsYear.html'
	});

	$routeProvider.when('/records/current', {
		controller: 'RecordsController',
		templateUrl: '/pages/records.html'
	})

	$routeProvider.when('/records/create', {
		controller: 'RecordsController',
		templateUrl: '/pages/createRecord.html'
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
	})

	$routeProvider.when('/admin/results/:sport',{
		controller: 'AdminResultsController',
		templateUrl: '/pages/editResults.html'
	});

	// $routeProvider.otherwise({
	// 	redirectTo: '/home'
	// });
});