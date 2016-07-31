$ = require 'jQuery'
moment = require 'moment'
Vue = require 'Vue'
VueTouch = require 'vue-touch'

store = require './store'
toast = require './toast'

if !store.getState()?
  # store.init()
  store.setDummy()

# 開発用
if !store.getState().appinfo?
  # store.init()
  store.setDummy()


# タッチ操作を登録
VueTouch.registerCustomEvent('dualtap', {
  type: 'tap',
  pointers: 2
})
VueTouch.registerCustomEvent('tripletap', {
  type: 'tap',
  pointers: 3
})
Vue.use VueTouch

window.vue = null

$ ->
  # コンポーネントの登録
  Vue.component('modal-statistics', {
    template: "#modal-statistics",
  })
  Vue.component('modal-create', {
    template: "#modal-create"
  })
  Vue.component('modal-deals', {
    template: "#modal-deals"
  })
  Vue.component('modal-configs', {
    template: "#modal-configs"
  })

  Vue.component('statistics-gender', {
    template: "#statistics-gender",
  })
  Vue.component('statistics-age', {
    template: "#statistics-age",
  })
  Vue.component('statistics-sample', {
    template: "#statistics-sample",
  })

  window.vue = new Vue(
    el: '#vue'
    data:store.getState()
    methods:

      # =================
      #      util
      # =================

      # 保存
      save: () ->
        # stateの内容は保存しない
        # data =  $.extend({}, this.$data)
        # data.state
        # store.setState(data)
        store.setState(this.$data)

      # 現在の使用容量
      dispStorage: () ->
        str = JSON.stringify(store.getState())
        str_length = encodeURIComponent(String(str)).replace(/%../g,"x").length
        str_size = Math.floor( str_length / 1048576 * 100) * 0.01
        return str_size+"MB"

      # 現在時刻を表示
      dispTime: (timestamp) ->
        return moment(timestamp).format("HH時mm分")

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



      # =================
      #      create
      # =================

      # アイテムを新規追加
      createItem: () ->
        id = moment().format("YYYYMMDDHHmmss")
        name = $(".create .js-item-name").val()
        thumb = $(".create .js-item-thumb").val()
        price = $(".create .js-item-price").val()
        if name.length == 0
          alert "項目名を入力してください"
          return false
        if thumb.length == 0
          alert "サムネイルを登録してください"
          return false
        if price.length == 0
          alert "値段を入力してください"
          return false
        item = {
          id: id
          name: name
          thumb: thumb
          price: price
          count: 0
        }
        this.$data.items.push item
        this.$data.state.modalContent = null
        this.save()
        toast.show('アイテムを追加しました','success')

      # ファイル選択時に実行
      getDataUrl: () ->
        # 画像をエンコード
        _this = this
        files = $(".create .js-image-upload").prop('files')
        if files.length == 0
          console.log 'ファイル選択してない！'
        else
          file = files[0]
          reader = new FileReader()
          reader.onerror = ->
            alert 'ファイル読み取りに失敗しました'

          reader.onload = ->
            # 成功時に縮小関数内で非同期に処理する
            _this.makeSmall(reader.result)

          reader.readAsDataURL(file)

      # 画像を圧縮
      makeSmall: (data) ->
        _this = this
        # 画像データの縦横サイズを取得する
        rectWidth = 280
        image = new Image()
        image.src = data

        # ロード完了後に非同期処理させる
        $(image).bind 'load', ->
          width = image.width
          height = image.height
          # 画像の大きさをキメる
          if width > height
            new_width = width * rectWidth / height
            new_height = rectWidth

          else
            new_width = rectWidth
            new_height = height * rectWidth / width

          # 画像出力用のキャンバスを定義
          canvas = document.createElement("canvas")
          canvas.width = new_width
          canvas.height = new_height

          # 画像をセットしてデータURLにして返す
          canvas.getContext("2d").drawImage(image, 0, 0, new_width, new_height)
          dataUrl =  canvas.toDataURL("image/jpeg", 0.4)
          $(".create .js-item-thumb").val(dataUrl)
          $(".create .js-show-thumb").show()
            .find('img').attr('src', dataUrl)



      # =================
      #      item
      # =================

      # idからアイテムを探す
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

      # カート内のアイテムの値段の合計
      cartPrice: () ->
        price = 0
        current =  this.$data.current
        for item_id in current.items
          item = this.findItem(item_id)
          if item?
            price += Number(item.price)
        return price

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

      # 特定のアイテムそのものを削除
      destroyItem: (item) ->
        return unless window.confirm('削除してもよろしいですか？') == true
        items =  this.$data.items
        items.some( (v, i) ->
          if v.id == item.id
            items.splice(i,1)
        )
        this.save()
        location.reload()



      # =================
      #      decide
      # =================

      # statisticsが有効の時のみtrue
      statistics_f: () ->
        if this.$data.configs.statistics_f == true
          return true
        return false

      # 決済ボタンを押された時の挙動
      enterDealActions: () ->
        # 何もない時は追加しない
        if this.cartPrice() == 0
          toast.show("何も選択されてないです！",'warning')
          return
        # 質問フラグが立ってれば、アンケートに移行
        if this.$data.configs.statistics_f
          this.showStatisticsInput()
          return
        # 何もなければ即決済
        this.decide()

      # アンケート表示
      showStatisticsInput: () ->
        # state.modalContentに値を入れると自動でモーダルが出る
        this.$data.state.modalContent = 'modal-statistics'

      # アンケート確定
      submitStatisticsInput: () ->
        # 値取得
        gender = $('input[name="gender"]:checked').val()
        age    = $('input[name="age"]:checked').val()
        sample = $('input[name="sample"]:checked').val()

        # アンケート情報をdealに含ませる
        deal = this.$data.current
        deal.statistics = {
          gender:gender
          age:age
          sample:sample
        }
        # 決済に移行
        this.$data.state.modalContent = null
        this.decide(deal)

      # 決済する
      decide: (deal = this.$data.current) ->
        deal.created = moment().format("YYYY-MM-DD HH:mm:ss")
        deal.price = this.cartPrice()
        deal.items.sort (a,b) ->
          return a - b
        this.$data.deals.unshift($.extend({}, deal))
        # 各アイテムの販売数を増やす
        for item_id in deal.items
          this.increseItemCount(item_id)
        this.clearCart()
        this.save()
        toast.show("保存しました！")



      # =================
      #      deals
      # =================

      # 合計売上
      earnings: () ->
        eaning = 0
        deals =  this.$data.deals
        for deal in deals
          if deal.price?
            eaning += deal.price
        return eaning

      # 配列内の同じ要素の数を返す
      countItemInItems: (item_ids, item_id) ->
        return item_ids.filter((id)->
          id == item_id
        ).length



      # =================
      #      modal
      # =================

      # stateのモーダルコンテントが存在するなら、モーダルを表示
      modal_f: () ->
        if this.$data.state? && this.$data.state.modalContent?
          $('body').css {
            position: 'fixed',
            top: -1 * $(window).scrollTop()
          }
          return true
        $('body').removeAttr('style')
        return false

      # モーダルを隠す
      hideModal: () ->
        this.$data.state.modalContent = null



      # =================
      #       menu
      # =================

      # メニュー表示中のフラグ
      menu_f: () ->
        if this.$data.state.menu_f == true
          if this.$data.state.currentScroll == null
            this.$data.state.currentScroll = $(window).scrollTop()
            $('body').css {
              position: 'fixed',
              top: -1 * this.$data.state.currentScroll
            }
          return true
        if this.$data.state.currentScroll != null
          currentScroll = this.$data.state.currentScroll
          this.$data.state.currentScroll = null
          $('body').removeAttr('style')
          window.scrollTo(0,currentScroll)

        return false

      # メニューを開閉
      toggleMenu: () ->
        this.$data.state.menu_f = !this.$data.state.menu_f

      # メニューを閉じて引数のモーダルを開く
      segue: (modalContent) ->
        this.$data.state.menu_f = false
        this.$data.state.modalContent = modalContent



      # =================
      #     configs
      # =================

      # コンフィグの内容を更新
      changeConfig: (key, value) ->
        this.$data.configs[key] = value
        this.save()


  )
