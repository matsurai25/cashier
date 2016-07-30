gulp         = require 'gulp'
rename       = require 'gulp-rename'
jade         = require 'gulp-jade' #jadeのコンパイル
coffee       = require 'gulp-coffee' #coffeeのコンパイル
sass         = require 'gulp-sass' #SASSのコンパイル
plumber      = require 'gulp-plumber' #エラーが起きてもtaskを停止しない
autoprefixer = require 'gulp-autoprefixer' #プレフィックスを自動で
browser      = require 'browser-sync' #ブラウザでのプレビュー
browserify   = require 'gulp-browserify'
# source       = require 'vinyl-source-stream' # browserifyで使用
require 'date-utils' # 日時取得

defaultPath = "dist/"

# 基本作業時用
gulp.task 'default', ['build', 'watch', 'server']

gulp.task "server", ->
  browser(
    server:
      baseDir : "./dist/"
      index   : "index.html"
  )

gulp.task "reload", ->
  browser.reload()

gulp.task 'build:coffee', ->
  gulp.src 'src/coffee/main.coffee', read: false
    .pipe plumber()
    .pipe browserify
      extensions: ['.coffee'] # CoffeeScriptも使えるように
      transform: ['coffeeify']
    .pipe rename 'bundle.js'
    .pipe gulp.dest __dirname+'/dist/assets/js/'

gulp.task 'build:scss', ->
  gulp.src('src/scss/*.scss')
    .pipe(plumber({
      errorHandler: (err) ->
        console.log(err.messageFormatted)
        this.emit('end')
    }))
    .pipe(sass())
    .pipe(autoprefixer())
    .pipe gulp.dest defaultPath+'assets/css/'

gulp.task 'build:jade', ->
  # index以外のjadeファイルは/c/以下に
  gulp.src(['src/jade/**/*.jade','!src/jade/**/_*.jade'])
    .pipe(plumber())
    .pipe(jade({
      basedir: __dirname+"/src/jade/"
      pretty: true
    }))
    .pipe gulp.dest defaultPath

gulp.task 'watch', ->
  gulp.watch 'src/**/*.jade', ['build:jade']
  gulp.watch 'src/**/*.scss', ['build:scss']
  gulp.watch 'src/**/*.coffee', ['build:coffee']
  gulp.watch 'dist/**/*.*', ['reload']

gulp.task 'build', [
  'build:scss'
  'build:coffee'
  'build:jade'
]
