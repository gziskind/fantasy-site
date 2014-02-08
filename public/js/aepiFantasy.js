angular.module('aepi-fantasy',['ngRoute'], function($routeProvider) {
	$routeProvider.when('/home',{
		controller: 'HomeController',
		templateUrl: 'pages/home.html'
	})
	
	$routeProvider.when('/baseball', {
		controller: 'BaseballController',
		templateUrl: 'pages/baseball.html'
	});

	$routeProvider.when('/football', {
		controller: 'FootballController',
		templateUrl: 'pages/football.html'
	})

	$routeProvider.otherwise({
		redirectTo: '/home'
	});
});