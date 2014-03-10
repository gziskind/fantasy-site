angular.module('aepi-fantasy',['ngRoute','ngResource'], function($routeProvider) {
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

	// $routeProvider.otherwise({
	// 	redirectTo: '/home'
	// });
});