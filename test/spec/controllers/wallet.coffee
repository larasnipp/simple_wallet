'use strict'

describe 'Controller: WalletCtrl', ->

  # load the controller's module
  beforeEach module 'simpleWalletApp'

  WalletCtrl = {}
  scope = {}

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope) ->
    scope = $rootScope.$new()
    WalletCtrl = $controller 'WalletCtrl', {
      $scope: scope
    }

  it 'should set the balance to 7', ->
    expect(scope.balance).toBe 7
