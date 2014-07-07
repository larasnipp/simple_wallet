'use strict'

angular.module('simpleWalletApp')
  .controller 'WalletCtrl', ($scope, $http) ->
    messages = new Firebase("https://mason.firebaseio.com/messages")
    $scope.current_network = 'dogecoin'
    $scope.send = =>
      messages.push(
        userId: $scope.userId
        body: $scope.message
      )
      $scope.message = ''

    $scope.pay = =>
      amount = Math.floor(parseFloat($scope.amount) * 100000000)
      wallet = $scope.wallets[$scope.current_network]
      tx = wallet.createTx(
        $scope.payToAddress,
        amount
      )
      wallet.processConfirmedTx(tx)
      console.log(tx.toHex())
      $http(
        method: 'POST'
        url: 'http://insight.bitpay.com/api/tx/send',
        data: { rawtx: tx.toHex() }
      ).error( (a,b,c)->
        console.log(a)
        console.log(b)
        console.log(c)

      )

      $scope.amount = ''
      $scope.payToAddress = ''


    firebase = new Firebase("https://mason.firebaseio.com/addresses")

    window.auth = new FirebaseSimpleLogin firebase, (error, user) =>
      if error
        console.log(error)
        # alert(error)
        # for e in error
        #   alert(e)
      if user
        firebase_user = new Firebase("https://mason.firebaseio.com/users/#{user.id}")
        firebase_user.update
          id: user.thirdPartyUserData.id
          first_name: user.thirdPartyUserData.first_name
          last_name: user.thirdPartyUserData.last_name
          name: user.thirdPartyUserData.name
          picture: user.thirdPartyUserData.picture.data.url

        $scope.userId = user.thirdPartyUserData.id
        messages.limit(2).on "child_added", (message) =>
          firebase_user = new Firebase("https://mason.firebaseio.com/users/#{user.thirdPartyUserData.id}")
          firebase_user.on 'value', (user)->
            $('.messages').append("<div>#{user.val().first_name}<img src=#{user.val().picture}>: #{message.val().body}</div>")
        $scope.picture = user.thirdPartyUserData.picture.data.url
        $scope.$apply()
      else
        auth.login('facebook', preferRedirect: true)

    if !localStorage['walletSeed']?
      localStorage['walletSeed'] = JSON.stringify(secureRandom(32, { type: 'Array' }))

    $scope.wallets = {}
    blockchain_servers =
      bitcoin: 'http://insight.bitpay.com'
      dogecoin: 'http://bitcoin.masonforest.com:3000'
    for network in ['dogecoin', 'bitcoin']
      wallet = new Bitcoin.Wallet(new buffer.Buffer(JSON.parse(localStorage['walletSeed'])), Bitcoin.networks[network])
      wallet.generateAddress()
      p = $http.get "#{blockchain_servers[network]}/api/txs/?address=#{wallet.addresses[0]}"
      p.success (response)=>
        console.log(response)
        txs = _.map response.txs, (tx) ->
            transaction = new Bitcoin.Transaction()
            transaction.version = tx.version
            transaction.ins = _.map tx.vin, (theIn) ->
              hash: Array.prototype.reverse.call(new buffer.Buffer(theIn.txid, 'hex'))
              index: theIn.n
              script: new Bitcoin.Script.fromASM(theIn.scriptSig.asm)
              sequence: theIn.sequence
            transaction.outs = _.map tx.vout, (out)->
              out.address = Bitcoin.Address.fromBase58Check(out.scriptPubKey.addresses[0])
              out.script = new Bitcoin.Script.fromASM(out.scriptPubKey.asm)
              out.value = Math.floor(parseFloat(out.value)*100000000)
              out

            window.tx = transaction
            transaction

        _.each txs.reverse(), (tx)->
          wallet.processConfirmedTx(tx)
    $scope.wallets[network] = wallet
    window.wallets = $scope.wallets

    s = io.connect("http://insight.bitpay.com/")
    # s.on bitcoin_wallet.addresses[0], (data) ->
    #   $http.get("http://insight.bitpay.com/api/tx/#{data}").success((tx)->
    #     tx.hash = tx.txid
    #     tx.ins = _.map tx.vin, (theIn)->
    #       theIn.outpoint = {}
    #       theIn.outpoint.hash = theIn.txid
    #       theIn.outpoint.index = parseInt(theIn.vout)
    #       theIn.scriptSig = theIn.scriptSig.asm
    #       theIn.address = Bitcoin.Address.fromBase58Check(theIn.addr)
    #       theIn

    #       # TODO import outs scripts
    #     tx.outs = _.map tx.vout, (out)->
    #       out.address = Bitcoin.Address.fromBase58Check(out.scriptPubKey.addresses[0])
    #       out.scriptPubKey = null
    #       out

    #     bitcoin_wallet.processTx(Bitcoin.Transaction(tx))
    #     $scope.balance = bitcoin_wallet.getBalance()/1000000
    #   )

    # s.on "connect", ->
    #   s.emit "subscribe", bitcoin_wallet.addresses[0]
    #   s.emit "subscribe", "tx"
    #   s.emit "subscribe", "inv"

    p.error (response)->
      console.log(response)

    $scope.amount = 0.0002
    $scope.payToAddress = '1LoBLNKPEdy4GwYWdaDLaTRbB7BBC9dZP3'
    $scope.networks =
      'bitcoin':
        name: 'Bitcoin'
        abbreviation: 'BTC'
      'dogecoin':
        name: 'Dogecoin'
        abbreviation: 'DOGE'


