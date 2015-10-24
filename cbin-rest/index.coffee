restify       = require 'restify'
Sequelize     = require 'Sequelize'
fs            = require 'fs'
utils         = require './utils'
helpers       = require './helpers'
configs       = require './configs'

getSequelizeInstance = (configs) ->
  sequelize  = new Sequelize configs.db.database, configs.db.username, configs.db.passwd, configs.db.options

getDirs = (dir) ->
  throw new Error "dir 'models' is not found" unless models  = utils.dirFileNames "#{dir}/models"
  throw new Error "file 'routes' is not found" unless routes  = require "#{dir}/routes"
  throw new Error "file 'configs' is not found" unless _configs = require "#{dir}/configs"
  return {
    models: do ->
      _.chain models
        .mapObject (x) ->
          require x
        .mapObject (x) ->
          return unless x.associations
          _.each x.associations, (a, k) ->
            x.definition[k]?(a...)
          x.definition
        .value()
    routes
    configs: _.extend {}, configs, _configs
  }

initServer = (configs) ->
  server = restify.createServer
    certificate: configs.server.certificate
    key: configs.server.key
    name: "myApp"
  server.use restify.queryParser()
  initRoutes routes, server
  server

initRoutes = (routes, server) ->
  _.each routes, (x) ->
    if x[0] is configs.restSignal
      _.each x.shift(), (routeArray) ->
        handleRoute routeArray
    else handleRoute x

handleRoute = (routeArray) ->


module.exports =
  #helpers
  helpers: helpers.forExports
  #init
  init: (dir) ->
    #找到基本的目录文件
    {models, routes, configs} = getDirs dir
    #初始化sequelize
    sequelize = getSequelizeInstance configs
    #初始化服务
    server = initServer configs
    #初始化helpers
    helpers.init models, routes, configs

    {
      #instance
      sequelize: sequelize
      #server
      server: server
      #开启服务
      start: () ->
        server.listen configs.server.port
      #同步数据库
      sync: () ->
        sequelize.drop().then () ->
          sequelize.sync()
    }
