cson           = require 'cson'
{EventEmitter} = require 'events'
_              = require 'lodash'
path           = require 'path'
debug = require('debug')('meshblu-connector-netscaler:index')
GetCountOfNetscalerResources = require './jobs/get-count-of-netscaler-resources'

CONFIG_SCHEMA       = cson.requireFile path.join(__dirname, '../schemas/config.cson')
MESSAGE_SCHEMA      = cson.requireFile path.join(__dirname, '../schemas/message.cson')
MESSAGE_FORM_SCHEMA = cson.requireFile path.join(__dirname, '../schemas/message-form.cson')

class NetscalerConnector extends EventEmitter
  constructor: ->
    super wildcard: true

  close: (callback) =>
    debug 'on close'
    callback()

  isOnline: (callback) =>
    callback null, running: true

  onConfig: ({options}) =>
    @options = _.pick options, 'username', 'password', 'hostAddress'

  onMessage: (message) =>
    {devices, fromUuid, payload} = message
    return if '*' in devices
    return if fromUuid == @uuid
    return unless payload?.metadata?

    console.log 'message', JSON.stringify message

    job = new GetCountOfNetscalerResources({@options})
    job.do payload, (error, response) =>
      
      {metadata,data} = response
      @emit 'message', {
        devices: [fromUuid]
        payload:
          from: message.metadata.flow.fromNodeId
          metadata: metadata
          data: data
      }

  start: (device) =>
    {@uuid,octoblu} = device
    debug 'started', @uuid
    octoblu ?= {}
    octoblu.flow ?= {}
    octoblu.flow.forwardMetadata = true

    @emit 'update',
      optionsSchema:     CONFIG_SCHEMA
      messageSchema:     MESSAGE_SCHEMA
      messageFormSchema: MESSAGE_FORM_SCHEMA
      octoblu:           octoblu

module.exports = NetscalerConnector
