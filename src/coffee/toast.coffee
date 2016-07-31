$ = require 'jQuery'

toast =
  show: (text, type = 'default') ->
    $msg = $('<div></div>',
      text:text
      class:"toast #{type}"
    )

    setTimeout((()->
      $msg.addClass('out')
      setTimeout((()->
        $msg.remove()
      ),1000)
    ),1500)
    $('.toasts').append($msg)


module.exports = toast
