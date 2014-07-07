'use strict'

angular
  .module('simpleWalletApp', [
    'ngCookies',
    'ngResource',
    'ngSanitize',
    'ngRoute',
    'ja.qr'
  ])
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'WalletCtrl'
      .otherwise
        redirectTo: '/'
