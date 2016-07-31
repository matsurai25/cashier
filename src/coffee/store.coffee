$ = require 'jQuery'
model = require './model'
dummy = require './dummy'

store =
  config:
    app_name:'cashier'
  setState: (data) ->
    data = $.extend({}, data)
    data.state = model.state
    localStorage.setItem store.config.app_name,JSON.stringify data
  # 対象を比較して構造を維持したままマージする
  mergeState: (data) ->
    console.log 'mergeState'
    # localStorage.setItem store.config.app_name,JSON.stringify data
  # 指定した配列にpushする
  insertState: (data) ->
    console.log 'insertState'
    # localStorage.setItem store.config.app_name,JSON.stringify data
  getState:->
    return JSON.parse localStorage.getItem store.config.app_name
  clear:->
    localStorage.removeItem store.config.app_name
  log:->
    console.log store.getState()
  setDummy:->
    console.log 'setDummy'
    store.setState dummy
    # console.log store.getState()
  init:->
    console.log 'init'
    store.setState model
    console.log "初期化しました"
    # console.log store.getState()
# store.setState(json)
# store.log()

module.exports = store
