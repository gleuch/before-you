window.BeforeYou = ->
  this.visible_items = 20
  this.zindex_high = this.visible_items * 1000
  this.x_offset = 24
  this.y_offset = 6
  this.z_offset = 200
  this.z_offset_start = this.z_offset * 3
  this.you = 'uuidhere'
  this.deg2rad = Math.PI / 180
  this.rad2deg = 180 / Math.PI
  this.mouse_down = false
  this.mouse_x = 0
  this.mouse_y = 0
  return this;


$.extend BeforeYou.prototype, {
  loaded : false


  load : ->
    this.setup()
    $('body').addClass 'load'
    this.loaded = true
    return this

  setup : ->
    $this = this
    this.resize()
    $(window).on 'resize', ->
      $this.resize()

    $('.queue').on('mousedown', (e)->
      $this.mouse_down = true
      $this.mouse_x = e.screenX
      $this.mouse_y = e.screenY
    ).on('mouseup', (e)->
      $this.mouse_down = false
      $this.mouse_x = 0
      $this.mouse_y = 0
      $(this).removeClass('drag')
    ).on('mousemove', (e)->
      if $this.mouse_down
        $(this).addClass('drag')
        $this.move(e.screenX - $this.mouse_x)
        $this.mouse_x = e.screenX
        $this.mouse_y = e.screenY
    )

    $('#before-you-queue').find('img').each (i) ->
      # x = -(i * $this.x_offset)
      # y = -(i * $this.y_offset)
      z = -(i * $this.z_offset) + $this.z_offset_start

      setTimeout( (->
        $(this).attr('data-index', i).css({
          'opacity' : (1 - (i / $this.visible_items))
          'z-index': $this.zindex_high - i
          # 'margin-left' : x + 'px'
          # 'margin-top' : y + 'px'
          'transform' : 'rotateY(25deg) translateZ(' + z + 'px)'
          # perspective here  
        }).data('default-transform', $(this).css('transform'))

        setTimeout( (-> 
          $(this).addClass('done') 
        ).bind(this), 850)
      ).bind(this), (100 * i) );

      $this.item.click this
      # $(this).on('click', ->
      #   $this.item.click().bind(this)
      # ).on('mouseover', ->
      #   $this.item.mouseover().bind(this)
      # ).on('mouseout', ->
      #   $this.item.mouseout().bind(this)
      # )
      return


  move : (z)->
    this.z_offset_start += z
    $this = this
    $('#before-you-queue').find('img').each (i) ->
      z = -(i * $this.z_offset) + $this.z_offset_start

      $(this).attr('data-index', i).css({
        # TODO : MAKE THIS BE BASED ON VALUE NEAR 0 zindex, fade those +/- z index at 0
        'opacity' : (1 - (i / $this.visible_items))
        'transform' : 'rotateY(25deg) translateZ(' + z + 'px)'
      }).data('default-transform', $(this).css('transform'))
    return
    


  resize : ->
    w = $(window).width()
    h = $(window).height()
    this.angle = Math.atan(h / w) * this.rad2deg
    # $('.queue').css('transform', 'translateZ( 0 ) rotate3d(' + -210 + ',360,-40,' + (this.angle) + 'deg)')
    # p = if w > h then 1.5 else .5
    p = 1
    $('.queue-area').css {
      #'perspective' : ($(window).width() / 2) + 'px'
      'perspective' : '700px'
      'perspective-origin' : (((h / w) - p) * 100) + '% -35%'
    }

  mousedrag : (e)->

  item : {
    open : null

    mouseover : (el)->
      $(el).on 'mouseover', ->
        $(this).addClass 'hover'

    mouseout : (el) ->
      $(el).on 'mouseout', ->
        $(this).removeClass 'hover'

    click : (el)->
      $this = this;
      $(el).on 'click', ->
        if $this.open == $(this).attr('data-index')
          $(this).removeClass('open hover').css 'transform', $(this).data('default-transform')
          $this.open = null
        else
          $this.open = $(this).attr('data-index')
          $(this).parent('.queue').find('img').each ->
            if $(this).data('default-transform')
              $(this).css('transform', $(this).data('default-transform'))
            $(this).removeClass('open');
          $(this).addClass('open').css('transform', $(this).data('default-transform') + ' rotateY(-25deg)');
  }
}

$ ->
  window.$you = new BeforeYou();
  window.$you.load()