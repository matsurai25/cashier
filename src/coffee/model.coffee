model =
  items : []
  deals : []
  current :
    items:[]
  state :
    modalContent: null
    menu_f: false
    currentScroll: null
  configs :
    statistics_f: true
    sync_available: false
    sync_f: false
    identifier: null
    username: null

model.appinfo = require './appinfo'

module.exports = model
