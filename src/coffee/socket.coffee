$ = require 'jQuery'
io = require 'socket.io-client'
toast = require './toast'

class Socket
  url = 'matsurai25.xyz:18025'
  constructor: (vue) ->
    return if !vue?
    _this = this
    _this.io = io(url)
    _this.vue = vue
    _this.identifier = vue.$data.configs.identifier
    _this.username = vue.$data.configs.username
    _this._listen()

  _listen: () ->
    _this = this
    channels =
      # サーバーOKなので、IDを送信して部屋に入る
      request_identifier: () ->
        data =
          identifier: _this.identifier
          username: _this.username
        _this.io.emit("send_identifier",data)

      # 誰かの接続イベント
      connected: (data) ->
        if data.username == _this.username
          toast.show("接続完了:#{_this.identifier}")
        else
          toast.show("#{data.username}さんが接続されました")

      # 完全同期イベントを受け取る
      sync_all: (data) ->
        return if data.username == _this.username
        return if !window.confirm("#{data.username}さんのデータと完全同期します。")
        console.log("完全同期")
        _this.vue.$data.items = data.data.items
        _this.vue.$data.deals = data.data.deals
        _this.vue.save()
        location.reload()

      # 同期イベントを受け取る
      sync: (data) ->
        console.log "i"
        return if data.username == _this.username
        locale_ids = _this.vue.$data.deals.map((x)-> x.created)
        remote_ids = data.data.deals.map((x)-> x.created)

        for i in [0...remote_ids.length]
          continue if locale_ids.indexOf(remote_ids[i]) >= 0
          _this.vue.$data.deals.push(data.data.deals[i])
        _this.vue.updateItemCount()
        _this.vue.$data.deals.sort( (a,b) ->
          if(a.created < b.created)
            return 1
          if(a.created > b.created)
            return -1
          return 0
        )
        _this.vue.save()
        toast.show("#{data.username}さんが更新")


    for key, func of channels
      _this.io.on(key, func)

  close: () ->
    _this = this.io.disconnect()
    console.log("disconnect!!!")

  syncAll: () ->
    _this = this
    return if !window.confirm("同期中の相手へ、現在の全てのデータを共有します。")
    data =
      identifier: _this.identifier
      username: _this.username
      data:
        items: _this.vue.$data.items
        deals: _this.vue.$data.deals
    console.log data
    _this.io.emit("sync_all", data)

  sync: () ->
    _this = this
    data =
      identifier: _this.identifier
      username: _this.username
      data:
        deals: _this.vue.$data.deals
    _this.io.emit("sync", data)

module.exports = Socket
