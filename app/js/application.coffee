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
    _t.ws = new WebSocket(ws_schema + window.document.location.host + '/')

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
    alert('latest')

  # Get information about self, if processing
  getSelf : ->
    this.request {
      action : 'self'
    }

  respondSelf : (data)->
    alert('self')


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
