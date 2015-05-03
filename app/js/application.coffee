window.b4u = ->
  this.loaded = false
  this.ws = false
  this.prev_id = false
  this.next_id = false
  this.view_date = null
  this.view_index = 0;
  this.items = []
  return this


$.extend b4u.prototype, {
  loaded : false

  # Load upb4u
  load : ->
    this.setup()
    return this

  # Setup for WebSockets, etc
  setup : ->
    _t = this

    ws_schema = if window.document.location.protocol.match(/^https/i) then 'wss://' else 'ws://'
    ws_etc = if window.document.location.host == 'b4u.today' then '/websocket/' else '/'
    _t.ws = new WebSocket(ws_schema + window.document.location.host + ws_etc)

    _t.ws.onopen = ->
      $(window).trigger('b4u:socket:ready')

    _t.ws.onclose = ->
      $(window).trigger('b4u:socket:close')

    _t.ws.onerror = ->
      $(window).trigger('b4u:socket:error')
      console.log(arguments)

    _t.ws.onmessage = (message)->
      try
        data = JSON.parse(message.data)
        _t.response(data)
      catch e
        console.log(arguments)


  # Generate canvas and start processing through items
  start : ->
    # this.canvas()


  # Canvas for showing the queue
  canvas : ->
    _t = this

    canvas = $('<canvas></canvas>').attr('id', 'b4u-canvas')
    $('body').append(canvas)

    _t.scene = new THREE.Scene()
    _t.camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 )
    _t.renderer = new THREE.WebGLRenderer({ canvas: canvas.get(0) })

    _t.renderer.setSize( window.innerWidth, window.innerHeight )
    document.body.appendChild( _t.renderer.domElement )

    geometry = new THREE.BoxGeometry( 1, 1, 1 )
    material = new THREE.MeshBasicMaterial( { color: 0x00ff00 } )
    cube = new THREE.Mesh( geometry, material )
    _t.scene.add( cube )

    _t.camera.position.z = 5

    render = ->
      requestAnimationFrame( render )

      cube.rotation.x += 0.01
      cube.rotation.y += 0.01

      _t.renderer.render(_t.scene, _t.camera)

    render()


  # Make a WebSocket request
  request : (data)->
    if !this.ws
      this.setup()
    this.ws.send( JSON.stringify(data) )


  # Routing for responses
  response : (data)->
    switch data.action
      when 'self'
        this.respondSelf(data.data)
      when 'latest'
        this.respondLatest(data.data)
      # when 'next'
      #   this.respondNext(data.data)
      # when 'previous'
      #   this.respondPrevious(data.data)


  # --- REQUEST FOR WEB ACTIONS ---

  # Get latest
  respondLatest : (data)->
    console.log('latest')

  # Get information about self, if processing
  getSelf : ->
    this.request {
      action : 'self'
    }

  respondSelf : (data)->
    console.log('self')


  # # Load the previous day
  # getPreviousDay : ->
  #
  # # Load the next day
  # getNextDay : ->
  #

  # # Paginate previous locations
  # getPrevious : ->
  #   this.request {
  #     action : 'previous',
  #     date : '',
  #     id : this.prev_id
  #   }
  # 
  # respondPrevious : (data)->
  #    alert('previous')
  # 
  # 
  # # Paginate next locations
  # getNext : ->
  #   this.request {
  #     action : 'next',
  #     date : '',
  #     id : this.next_id
  #   }
  # 
  # respondNext : (data)->
  #    alert('next')


  # --- UTILITIES ---
  setDate : (d) ->
    this.view_date = Date.parse d

  appendToQueue : (items) ->
    Array.prototype.push.apply(this.items, items)

  prependToQueue : (items) ->
    Array.prototype.unshift.apply(this.items, items)
    this.view_index += items.length;

}


# Start it up
$ ->
  window.$b4u = new b4u();
  window.$b4u.load()
  
  $(document).ready ->
    window.$b4u.start()