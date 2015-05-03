window.b4u = ->
  this.loaded = false
  this.ws = false
  this.prev_id = false
  this.next_id = false
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

    _t.ws.onerror = ->
      console.log(arguments)
      # alert('Connection Error')

    _t.ws.onmessage = (message)->
      try
        data = JSON.parse(message.data)
        _t.response(data)
      catch e
        console.log(arguments)
        # alert('Unknown error: ' + e)

    # this.canvas()

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


  # # Paginate previous locations
  # getPrevious : ->
  #   this.request {
  #     action : 'previous'
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
  #     action : 'next'
  #     id : this.next_id
  #   }
  # 
  # respondNext : (data)->
  #    alert('next')

}


$ ->
  window.$b4u = new b4u();
  window.$b4u.load()
  setTimeout ->
    window.$b4u.getSelf()
  , 500