$ = require 'jQuery'
moment = require 'moment'
Vue = require 'Vue'
Vue.config.devtools = false
VueTouch = require 'vue-touch'
d3 = require '../lib/d3.v3.min.js'

store = require './store'
toast = require './toast'
appinfo = require './appinfo'
window.neta = require './neta'

if !store.getState()?
  store.init()
  # store.setDummy()

# 最新バージョンじゃない場合にアラート
# if store.getState().appinfo.version < appinfo.version
#   alert("ブラウザに保存されているデータのバージョンが古いようです。上手くconfigから初期化すると上手く動くかと思います。")

console.log '%c3日目西さ18b%cで売り子している僕と握手！', 'color:rgb(250, 41, 129);font-weight:bold;text-decoration:underline', ''
console.log '桜木蓮先生の綺麗なイラスト本も買おうな！'
console.log '強い人は%cneta.github()%cしてね。', 'color:rgb(22, 50, 172);background:#EFEFEF;border-radius:3px;padding:3px;', ''

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

      # 数字をいい感じに
      formatNumber: (num) ->
        num = String(num)
        if num.length > 5
          return num.substr(0, num.length-3)+"k"
        if num.length > 3
          return num.substr(0, num.length-3)+','+num.substr(-3)
        return num
        # return moment(timestamp).format("HH時mm分")

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
          dataUrl =  canvas.toDataURL("image/jpeg", 0.5)
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
      earnings: (format = true) ->
        eaning = 0
        deals =  this.$data.deals
        for deal in deals
          if deal.price?
            eaning += deal.price
        if format == true
          return this.formatNumber(eaning)
        else
          return eaning

      # 累計取引回数
      countDeals: (format = true) ->
        if format == true
          return this.formatNumber(this.$data.deals.length)
        else
          return this.$data.deals.length

      # 累計取引アイテム数
      countDealItems: (format = true) ->
        count = 0
        deals =  this.$data.deals
        for deal in deals
          count += deal.items.length
        if format == true
          return this.formatNumber(count)
        else
          count

      # 配列内の同じ要素の数を返す
      countItemInItems: (item_ids, item_id) ->
        return item_ids.filter((id)->
          id == item_id
        ).length

      # dealsを空に
      clearDeals: () ->
        return if !window.confirm('取引情報をリセットします')
        this.$data.deals = []
        # 各アイテムの販売数を0に
        items =  this.$data.items
        for item in items
          item.count = 0
        this.save()
        location.reload()

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
        if this.$data.state.menu_f == true
          # 別プロセスで無理やり描画させるよ
          this.preventDashboardGraph()

      # メニューを閉じて引数のモーダルを開く
      segue: (modalContent) ->
        this.$data.state.menu_f = false
        this.$data.state.modalContent = modalContent


      # =================
      #     dashboard
      # =================

      # スライダー
      slideDashbordPanel: (orient) ->
        $content = $('.js-dashboard-content')
        $pager = $('.js-dashboard-pager')
        $pages = $pager.find('.page')
        index = $pages.index($pager.find('.page.on'))

        movedIndex = null
        if orient == 'next'
          if index+1 >= $pages.length
            # console.log "おおすぎ"
            return
          movedIndex = index+1
        else if orient == 'prev'
          if index == 0
            # console.log "なさすぎ"
            return
          movedIndex = index-1
        else
          return
        width = $content.width()
        $pages.eq(index).removeClass('on')
        $pages.eq(movedIndex).addClass('on')
        $content.css({transform:"translateX(#{movedIndex*width*-1}px)"})
        this.preventDashboardGraph()

      # 現在アクティブな画面のグラフ要素を取得してmakeに投げる
      preventDashboardGraph: ->
        _this = this
        setTimeout( ( ->
          $content = $('.js-dashboard-content')
          $pager = $('.js-dashboard-pager')
          $pages = $pager.find('.page')
          index = $pages.index($pager.find('.page.on'))
          $activeContainer = $content.find('.js-dashboard-container').eq(index)

          $activeContainer.find(".summary-donut").each((i,x)->
            $x = $(x)
            return if $x.hasClass('done')
            $x.addClass("graph-#{moment().unix()}-#{i}").addClass('done')
            # data-typeによって場合分け
            data = []
            switch $x.data('type')
              when 'items'
                items =  _this.$data.items
                for item in items
                  data.push
                    name:item.name
                    value:item.count
                break
              when 'genders'
                deals =  _this.$data.deals
                genders =
                  man:0
                  woman:0
                for deal in deals
                  if deal.statistics? && deal.statistics.gender?
                    genders[deal.statistics.gender]++
                for key, value of genders
                  name = ''
                  if key == 'man'
                    name = '男性'
                  else if key == 'woman'
                    name = '女性'
                  else
                    continue
                  data.push
                    name:name
                    value:value
                break
              when 'ages'
                deals =  _this.$data.deals
                ages =
                  '10':0
                  '20':0
                  '30':0
                  '50':0

                for deal in deals
                  if deal.statistics? && deal.statistics.age?
                    ages[deal.statistics.age]++
                for key, value of ages
                  name = ''
                  if key == '10'
                    name = '10代'
                  else if key == '20'
                    name = '20代'
                  else if key == '30'
                    name = '30代-40代'
                  else if key == '50'
                    name = '50代以上'
                  else
                    continue
                  data.push
                    name:name
                    value:value
                break

            data.sort( (a,b) ->
              if(a.value < b.value)
                return 1
              if(a.value > b.value)
                return -1
              return 0
            )
            _this.makeGraph(data,'.'+$(x).attr('class').split(' ').join('.'))
          )
        ), 10 )


      # 円グラフを書く
      # data = [{name:"新刊",value:100}]
      makeGraph: (data, targetSelector) ->
        return false if !data?

        $("#{targetSelector}").html("")

        # 横幅と高さ
        size = $("#{targetSelector}").width()
        radius = size / 2

        names = []
        data.forEach (x, i) ->
          names.push(x.name)

        pointIsInArc = (pt, ptData, d3Arc) ->
          # Center of the arc is assumed to be 0,0
          # (pt.x, pt.y) are assumed to be relative to the center
          r1 = arc.innerRadius()(ptData)
          r2 = arc.outerRadius()(ptData)
          theta1 = arc.startAngle()(ptData)
          theta2 = arc.endAngle()(ptData)

          dist = pt.x * pt.x + pt.y * pt.y
          angle = Math.atan2(pt.x, -pt.y)

          if angle < 0
            angle = angle + Math.PI * 2

          return (r1 * r1 <= dist) && (dist <= r2 * r2) &&
                 (theta1 <= angle) && (angle <= theta2)


        # 円弧の外径と内径を定義
        arc = d3.svg.arc()
            .outerRadius(radius - 10)
            .innerRadius(0)
        # パイを定義
        pie = d3.layout.pie()
            .sort(null)
            .value (d) ->
              return d.value

        svg = d3.select("#{targetSelector}").append("svg")
          .attr("width", size)
          .attr("height", size)
          .append("g")
          .attr("transform", "translate(" + size / 2 + "," + size / 2 + ")")


        # パイにデータを割り当て、パイを作成
        g = svg.selectAll(".arc")
          .data(pie(data))
          .enter().append("g")
          .attr("class", (d) ->
            return "pie-"+names.indexOf(d.data.name)
            )

        # 円弧を指定
        g.append("path")
          .attr("d", arc)
          .style("fill","none")
          # .style("stroke","rgba(255,255,255,0.4)")
          .style("stroke-width","1px")

        # ラベルをパイに表示
        g.append("text")
          .attr("transform",  (d) ->
            return "translate(" + arc.centroid(d) + ")"
            )
          .attr("dy", "-0.65em")
          .style("text-anchor", "middle")
          .style("font-size","0.9em")
          .text( (d) ->
            return d.data.name
            )
          .each( (d) ->
            bb = this.getBBox()
            center = arc.centroid(d)
            topLeft = {
              x : center[0] + bb.x,
              y : center[1] + bb.y
            }
            topRight = {
              x : topLeft.x + bb.width,
              y : topLeft.y
            }
            bottomLeft = {
              x : topLeft.x,
              y : topLeft.y + bb.height
            }
            bottomRight = {
              x : topLeft.x + bb.width,
              y : topLeft.y + bb.height
            }

            d.visible = pointIsInArc(topLeft, d, arc) &&
                       pointIsInArc(topRight, d, arc) &&
                       pointIsInArc(bottomLeft, d, arc) &&
                       pointIsInArc(bottomRight, d, arc)

          )
          .style('display', (d) ->
            if d.visible == false
              return "none"
            return "block"
          )
        # 数値をパイに表示
        g.append("text")
          .attr("transform",  (d) ->
            return "translate(" + arc.centroid(d) + ")"
            )
          .attr("dy", ".35em")
          .style("text-anchor", "middle")
          .text( (d) ->
            return d.data.value
            )
          .style("font-size","0.9em")
          .each( (d) ->
            bb = this.getBBox()
            center = arc.centroid(d)
            topLeft = {
              x : center[0] + bb.x,
              y : center[1] + bb.y
            }
            topRight = {
              x : topLeft.x + bb.width,
              y : topLeft.y
            }
            bottomLeft = {
              x : topLeft.x,
              y : topLeft.y + bb.height
            }
            bottomRight = {
              x : topLeft.x + bb.width,
              y : topLeft.y + bb.height
            }

            d.visible = pointIsInArc(topLeft, d, arc) &&
                       pointIsInArc(topRight, d, arc) &&
                       pointIsInArc(bottomLeft, d, arc) &&
                       pointIsInArc(bottomRight, d, arc)

          )
          .style('display', (d) ->
            if d.visible == false
              return "none"
            return "block"
          )
      # =================
      #     configs
      # =================

      # コンフィグの内容を更新
      changeConfig: (key, value) ->
        this.$data.configs[key] = value
        this.save()

      # CSVを作成
      makeCSV: () ->
        csv =
          content : ''
          line : (array) ->
            this.content += array.join(',')+'\n'
        csv.line(['■ 全体まとめ'])
        csv.line(['来客数','頒布した総数','総売上'])
        csv.line(["#{this.countDeals(false)}","#{this.countDealItems(false)}","#{this.earnings(false)}"])
        csv.line(['■ アイテム情報'])
        csv.line(['名前','単価','頒布個数','売上'])
        for item in this.$data.items
          row = []
          row.push(item.name)
          row.push(item.price)
          row.push(item.count)
          row.push(item.count*item.price)
          csv.line(row)
        csv.line(['■ 取引情報'])
        if this.statistics_f()
          csv.line(['時間','金額','頒布物','性別','年代'])
        else
          csv.line(['時間','金額','頒布物'])
        for deal in this.$data.deals
          row = []
          row.push(deal.created)
          row.push(deal.price)
          cell = []
          for item_id in deal.items
            item = this.findItem(item_id)
            if item?
              cell.push(item.name)
          row.push(cell.join("/"))
          if this.statistics_f()
            gender = {
              man:"男性"
              woman:"女性"
            }
            age = {
              '10':"10代"
              '20':"20代"
              '30':"30代-40代"
              '50':"50代以上"
            }
            row.push(gender[deal.statistics.gender])
            row.push(age[deal.statistics.age])
          csv.line(row)
        csv.line(['■ その他'])
        csv.line(['作成日',moment().format('YYYY/MM/DD HH:mm:ss')])
        csv.line(['アプリ名',appinfo.name])
        csv.line(['アプリバージョン',appinfo.version])
        csv.line(['url', location.href])
        csv.line(['作者', 'まつらい(@matsurai25)'])

        bom = new Uint8Array([0xEF, 0xBB, 0xBF])
        blob = new Blob([ bom, csv.content ], { "type" : "text/csv" })
        filename = "頒布レコーダ_#{moment().format('YYYY-MM-DD_HH-mm-ss')}.csv"
        if (window.navigator.msSaveBlob)
          window.navigator.msSaveBlob(blob, filename)
          window.navigator.msSaveOrOpenBlob(blob, filename)
        else
          a = document.createElement("a")
          a.href = URL.createObjectURL(blob)
          a.target = '_blank'
          a.download = filename
          a.click()

  )
