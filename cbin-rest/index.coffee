_             = require 'underscore'
configs       = require './configs'
CRest         = require './rest-class'

class Wraper

  constructor: (dir) ->
    @rest = new CRest dir, configs

  #开启服务
  start: () ->
    @rest.start()
    console.log "server start at #{@rest.configs.server.port}"
  #同步数据库
  sync: () ->
    @rest.sync()

module.exports = Wraper
