angular.module('aepi-fantasy',['ngRoute','ngResource'], function($routeProvider) {
	$routeProvider.when('/overall', {
		controller: 'ResultsController',
		templateUrl: '/pages/results.html'
	});

	$routeProvider.when('/:year', {
		controller: 'ResultsController',
		templateUrl: '/pages/resultsYear.html'
	});

	// $routeProvider.when('/home',{
	// 	controller: 'HomeController',
	// 	templateUrl: 'pages/home.html'
	// })
	
	// $routeProvider.when('/baseball', {
	// 	controller: 'BaseballController',
	// 	templateUrl: 'pages/baseball.html'
	// });

	// $routeProvider.when('/football', {
	// 	controller: 'FootballController',
	// 	templateUrl: 'pages/football.html'
	// })

	// $routeProvider.otherwise({
	// 	redirectTo: '/home'
	// });
});