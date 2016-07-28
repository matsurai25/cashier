$ = require 'jQuery'
Vue = require 'Vue'
VueTouch = require 'vue-touch'
Vue.use VueTouch
moment = require 'moment'

store = require './store'

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
        return moment(timestamp).format("HH時mm分")

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

      # itemの売上カウントを増やす
      increseItemCount: (item_id) ->
        item = this.findItem(item_id)
        item.count++
        this.save()

      # itemの売上カウントを減らす
      decreseItemCount: (item_id) ->
        item = this.findItem(item_id)
        item.count--
        this.save()

      # 決済する
      decide: () ->
        return if this.cartPrice() == 0 # 何もない時は追加しない
        deal =  this.$data.current
        deal.created = moment().format("YYYY-MM-DD HH:mm:ss")
        deal.price = this.cartPrice()
        this.$data.deals.unshift($.extend({}, deal))
        # 各アイテムの販売数を増やす
        for item_id in deal.items
          this.increseItemCount(item_id)
        this.clearCart()
        this.save()

      # カート内のアイテムの値段の合計
      cartPrice: () ->
        price = 0
        current =  this.$data.current
        for item_id in current.items
          item = this.findItem(item_id)
          if item?
            price += Number(item.price)
        return price

      # 合計売上
      earnings: () ->
        eaning = 0
        deals =  this.$data.deals
        for deal in deals
          if deal.price?
            eaning += deal.price
        return eaning

      # カート内のアイテムを全て削除
      clearCart: () ->
        current =  this.$data.current
        current.items = []
        current.price = 0
        current.created = null
        this.save()

      # カートにあるか判定してクラスを出力
      isAdded: (item) ->
        current =  this.$data.current
        if current.items.indexOf(item.id) >= 0
          return "added"

      # 特定のアイテムがカート内に何個あるか出力
      countAddedItem: (item) ->
        current =  this.$data.current
        count = 0
        for item_id in current.items
          if item.id == item_id
            count++
        return count

      # カートに追加したり削除したり
      toggleCart: (item) ->
        current =  this.$data.current
        if current.items.indexOf(item.id) < 0
          current.items.push(item.id)
          this.save()
        else
          # 全て削除
          new_items = []
          current.items.forEach( (v, i) ->
            if v != item.id
              new_items.push v
          )
          current.items = new_items
          this.save()

      # 特定のアイテムをカートに一つ追加
      addCartItem: (item) ->
        current =  this.$data.current
        current.items.push(item.id)
        this.save()

      # 特定のアイテムをカートから一つ削除
      removeCartItem: (item) ->
        current =  this.$data.current
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

      # ダミーで上書き
      setdummy: () ->
        if window.confirm("初期化し、ダミーをセットします。よろしいですか？")
          store.setDummy()
          location.reload()
  )
