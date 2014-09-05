window.BeforeYou = ->
  this.visible_items = 20;
  this.zindex_high = this.visible_items * 1000;
  this.x_offset = 24;
  this.y_offset = 6;
  this.z_offset = 100;
  this.you = 'uuidhere';

  $this = this;

  $('#before-you-queue').find('img').each (i) ->
    x = -(i * $this.x_offset);
    y = -(i * $this.y_offset);
    z = -(i * $this.z_offset);

    setTimeout( (->
      $(this).attr('data-index', i).css {
        'opacity' : (1 - (i / $this.visible_items))
        'z-index': $this.zindex_high - i
        # 'margin-left' : x + 'px'
        # 'margin-top' : y + 'px'
        'transform' : 'translateZ(' + z + 'px)'
        # perspective here
      }
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

  return this;


$.extend BeforeYou.prototype, {
  load : ->
    $('body').addClass 'load'

  setup : ->

  resize : ->

  mousedrag : ->

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
          $(this).data('default-transform', $(this).css('transform'))
          $(this).parent('.queue').find('img').each ->
            if $(this).data('default-transform')
              $(this).css('transform', $(this).data('default-transform'))
            $(this).removeClass('open');
          $(this).addClass('open').css('transform', $(this).data('default-transform') + ' rotate3d(-133,360,-39,-55deg)');
  }
}

$ ->
  $you = new BeforeYou();
  $you.load()