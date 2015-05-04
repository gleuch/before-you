window.b4u = ->
  this.loaded = false
  this.ws = false
  this.prev_id = false
  this.next_id = false
  this.view_date = null
  this.day_total = 0
  this.canvas = {
    step_y : 10
    step_z : 100
    step_index : 0
  }
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
    this.setup_canvas()


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


  # --- CANVAS ---

  # Canvas for showing the queue
  setup_canvas : ->
    _t = this

    _t.canvas.element = $('<canvas></canvas>').attr('id', 'b4u-canvas')
    $('body').append(_t.canvas.element)

    _t.canvas.scene = new THREE.Scene()
    _t.canvas.camera = new THREE.PerspectiveCamera( 70, window.innerWidth / window.innerHeight, 1, 1000 )
    _t.canvas.renderer = new THREE.WebGLRenderer({ alpha: true, canvas: _t.canvas.element.get(0) })
    _t.canvas.mouse = new THREE.Vector2()
    _t.canvas.geometry = new THREE.BoxGeometry( 100, 75, 1 )

    _t.canvas.camera.position.y = 0
    _t.canvas.camera.position.z = 0

    _t.redrawItems()
    _t.canvas.renderer.setSize( window.innerWidth, window.innerHeight )
    document.body.appendChild( _t.canvas.renderer.domElement )

    $(document)
      .on 'mousemove', _t.mousemove.bind(this)
      .on 'keydown', _t.keypress.bind(this)
    $(window).on 'resize', _t.resize.bind(this)

    _t.animate()

  #
  drawItem : (n,i) ->
    material = new THREE.MeshNormalMaterial { color: 0xFFFF00, transparent: true }
    mesh = new THREE.Mesh this.canvas.geometry, material
    mesh.uuid = n.id
    mesh.position.x = 0
    mesh.position.y = 0
    mesh.position.z = -this.canvas.step_z * (i + 1)
    mesh.matrixAutoUpdate = false
    mesh.updateMatrix()
    this.canvas.queue.add mesh

  #
  redrawItem : (uuid)->
    # z = 0
    # for n,i in this.canvas.queue.children
    #   #

  #
  redrawItems : ->
    # Items
    this.canvas.scene.remove this.canvas.queue
    this.canvas.queue = new THREE.Group()
    this.drawItem(n,i) for n,i in this.items
    this.canvas.camera.position.z = -this.canvas.step_z * this.canvas.step_index
    this.canvas.scene.add this.canvas.queue

    # Timeline
    # this.canvas.scene.remove this.canvas.timeline
    # this.canvas.timeline = new THREE.Group()
    # # DRAW TIMELINE
    # this.canvas.scene.add this.canvas.timeline

  #
  resize : (e)->
    this.canvas.camera.aspect = window.innerWidth / window.innerHeight
    this.canvas.camera.updateProjectionMatrix()
    this.canvas.renderer.setSize( window.innerWidth, window.innerHeight )

  #
  mousemove : (e)->
    e.preventDefault()
    this.canvas.mouse.x = ( e.clientX / window.innerWidth ) * 2 - 1
    this.canvas.mouse.y = - ( e.clientY / window.innerHeight ) * 2 + 1

  #
  keypress : (e)->
    if e.keyCode == 38 || e.keyCode == 40 # Up
      e.preventDefault()
      this.move_z e.keyCode

  #
  move_z : (c) ->
    if c == 38 # Up
      this.canvas.step_index++ if (this.items.length - 1) > this.canvas.step_index
    else if c == 40
      --this.canvas.step_index if this.canvas.step_index > 0

    z = -this.canvas.step_z * this.canvas.step_index

    new TWEEN.Tween( this.canvas.camera.position ).to( { z: z }, 250 ).start();

  #
  animate : ->
    requestAnimationFrame( this.animate.bind(this) )
    this.render_canvas()

  #
  render_canvas : ->
    this.canvas.renderer.render this.canvas.scene, this.canvas.camera
    TWEEN.update()


  # --- REQUEST FOR WEB ACTIONS ---

  # Get latest
  respondLatest : (data) ->
    this.prependToQueue([data])
    this.redrawItems()
    this.day_count++

  # Get information about self, if processing
  getSelf : ->
    this.request {
      action : 'self'
    }

  respondSelf : (data)->
    # try to find the mesh item, or prepend & move to it
    # for n,i in this.items
    #   if n.id == data.id
    #     this.items[i] = data
    #     this.redrawItem(data.id)
    #     return
    # 
    # this.prependToQueue([data])


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
    this.canvas.step_index += items.length

}


# Start it up
$ ->
  window.$b4u = new b4u();
  window.$b4u.load()
  
  $(document).ready ->
    window.$b4u.start()