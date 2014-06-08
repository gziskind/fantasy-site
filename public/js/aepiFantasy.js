angular.module('aepi-fantasy',['ngRoute','ngResource','ngCookies'], function($routeProvider) {
	$routeProvider.when('/results/overall', {
		controller: 'ResultsController',
		templateUrl: '/pages/results.html'
	});

	$routeProvider.when('/results/:year', {
		controller: 'ResultsController',
		templateUrl: '/pages/resultsYear.html'
	});

	$routeProvider.when('/records', {
		controller: 'RecordsController',
		templateUrl: '/pages/records.html'
	})

	$routeProvider.when('/records/:user', {
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
	})

	// $routeProvider.otherwise({
	// 	redirectTo: '/home'
	// });
});