'use strict'

angular.module('simpleWalletApp')
  .controller 'WalletCtrl', ($scope, $http) ->
    $scope.pay = =>
      amount = parseFloat($scope.amount) * 100000000
      tx = w.createTx(
        $scope.payToAddress,
        amount
      )

      console.log(tx.serializeHex())
      $http(
        method: 'POST'
        url: 'http://198.58.106.133:3000/api/tx/send',
        data: { rawtx: tx.serializeHex() }
      ).error( ->
        alert('broke')
      )

      $scope.amount = ''
      $scope.payToAddress = ''
      window.w.processTx(tx)
      $scope.balance = w.getBalance()

    # localStorage.removeItem('walletSeed')
    # localStorage.removeItem('addresses')

    # localStorage['walletSeed'] = JSON.stringify([195, 186, 243, 233, 12, 155, 64, 141, 49, 34, 98, 121, 39, 120, 197, 194, 16, 30, 221, 152, 173, 126, 40, 210, 140, 58, 203, 168, 184, 62, 23, 65])
    # localStorage['addresses'] = JSON.stringify(["1NuxSSfksZb6XZuUCskemQ3LFuvffedz1j"])


    firebase = new Firebase("https://mason.firebaseio.com/addresses")

    if !localStorage['walletSeed']?
      localStorage['walletSeed'] = JSON.stringify(secureRandom(32, { type: 'Array' }))

    window.w = new Bitcoin.Wallet(new buffer.Buffer(JSON.parse(localStorage['walletSeed'])))

    if localStorage['addresses']?
      w.addresses = JSON.parse(localStorage['addresses'])
    else
      w.generateAddress()
      firebase.push(address: w.addresses[0])
      localStorage['addresses'] = JSON.stringify(w.addresses)


    firebase.on "child_added", (message) =>
      $('.addresses').append("<div>#{message.val().address}</div>")

    p= $http.get("http://insight.bitpay.com/api/txs/?address=#{w.addresses[0]}")


    p.success (response)->
      # console.log(response)
      txs = _.map response.txs, (tx) ->
          console.log(tx)
          transaction = new Bitcoin.Transaction()
          transaction.hash = tx.blockhash
          transaction.ins = _.map tx.vin, (theIn) ->
            hash: new buffer.Buffer(theIn.txid, 'hex')
            index: theIn.n
            script: new Bitcoin.Script.fromBuffer(new buffer.Buffer((theIn.scriptSig.asm)))
            sequence: theIn.sequence

            # TODO import outs scripts
          transaction.outs = _.map tx.vout, (out)->
            out.address = Bitcoin.Address.fromBase58Check(out.scriptPubKey.addresses[0])
            out.script = new Bitcoin.Script.fromBuffer(new buffer.Buffer(out.scriptPubKey.asm))
            out.value = Math.floor(parseFloat(out.value)*10000000)
            out

          transaction

      _.each txs.reverse(), (tx)->
        console.log(tx)
        w.processConfirmedTx(tx)
      $scope.balance = w.getBalance()/10000000
        #w.processTransaction(new Bitcoin.Transaction(tx))

    s = io.connect("http://insight.bitpay.com/")
    s.on w.addresses[0], (data) ->
      $http.get("http://insight.bitpay.com/api/tx/#{data}").success((tx)->
        tx.hash = tx.txid
        tx.ins = _.map tx.vin, (theIn)->
          theIn.outpoint = {}
          theIn.outpoint.hash = theIn.txid
          theIn.outpoint.index = parseInt(theIn.vout)
          theIn.scriptSig = theIn.scriptSig.asm
          theIn.address = Bitcoin.Address.fromBase58Check(theIn.addr)
          theIn

          # TODO import outs scripts
        tx.outs = _.map tx.vout, (out)->
          out.address = Bitcoin.Address.fromBase58Check(out.scriptPubKey.addresses[0])
          out.scriptPubKey = null
          out

        console.log(Bitcoin.Transaction(tx))
        w.processTx(Bitcoin.Transaction(tx))
        $scope.balance = w.getBalance()/1000000
      )

    s.on "connect", ->
      s.emit "subscribe", w.addresses[0]
      s.emit "subscribe", "tx"
      s.emit "subscribe", "inv"

    p.error (response)->
      console.log(response)

    # console.log(w.addresses[0])
    $scope.address = w.addresses[0]
    $scope.amount = 0.0002
    $scope.payToAddress = '1EJj9pT9kEcitfkCFwiLyKVXmeNLz5Lz4V'

