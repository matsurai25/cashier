$ = require 'jQuery'
Vue = require 'Vue'
store = require './store'
moment = require 'moment'
if !store.getState()?
  # store.init()
  store.setDummy()

$ ->
  demo = new Vue(
    el: '#vue'
    data:store.getState()
    methods:
      save: () ->
        store.setState(this.$data)

      dispTime: (timestamp) ->
        return moment(timestamp).format("HH:mm:ss")

      createItem: () ->
        console.log "新規アイテムを登録"
        id = moment().format("YYYYMMDDHHmmss")
        name = $(".createitem .js-item-name").val()
        thumb = $(".createitem .js-item-thumb").val()
        price = $(".createitem .js-item-price").val()
        item = {
          id: id
          name: name
          thumb: thumb
          price: price
          count: 0
        }
        this.$data.items.push item
        this.save()
        $('body,html').animate({
          scrollTop: 0
        }, 500)

      findItem: (item_id) ->
        items =  this.$data.items
        for item in items
          if item.id == item_id
            return item

      increseItemCount: (item_id) ->
        item = this.findItem(item_id)
        item.count++
        this.save()

      decide: () ->
        deal =  this.$data.current
        deal.created = moment().format("YYYY-MM-DD HH:mm:ss")
        deal.price = this.cartPrice()
        this.$data.deals.unshift($.extend({}, deal))
        # 各アイテムの販売数を増やす
        for item_id in deal.items
          this.increseItemCount(item_id)
        this.clearCart()
        this.save()

      cartPrice: () ->
        price = 0
        current =  this.$data.current
        for item_id in current.items
          item = this.findItem(item_id)
          if item?
            price += Number(item.price)
        return price

      earnings: () ->
        eaning = 0
        deals =  this.$data.deals
        for deal in deals
          if deal.price?
            eaning += deal.price
        return eaning

      clearCart: () ->
        current =  this.$data.current
        current.items = []
        current.price = 0
        current.created = null
        this.save()

      # クラスを出力
      addedCartItem: (item) ->
        current =  this.$data.current
        if current.items.indexOf(item.id) >= 0
          return "added"

      # カートに追加したり
      toggleCart: (item) ->
        current =  this.$data.current
        if current.items.indexOf(item.id) < 0
          current.items.push(item.id)
          this.save()
        else
          current.items.some( (v, i) ->
            if v == item.id
              current.items.splice(i,1)
          )
          this.save()

      # 初期化
      initialize: () ->
        if window.confirm("初期化します。よろしいですか？")
          store.init()
          location.reload()

      # 初期化
      setdummy: () ->
        if window.confirm("初期化し、ダミーをセットします。よろしいですか？")
          store.setDummy()
          location.reload()
  )
