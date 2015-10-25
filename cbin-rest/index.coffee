_             = require 'underscore'
restify       = require 'restify'
Sequelize     = require 'Sequelize'
fs            = require 'fs'
utils         = require './utils'

{dir, configs, models, helpers, controllers, routes, sequelize, server} = {}

getConfigs = () ->
  throw new Error "file 'configs' is not found" unless _configs = require "#{dir}/configs"
  configs = _.extend {}, _configs, require './configs'

getSequelizeInstance = () ->
  config = configs.db
  sequelize  = new Sequelize config.database, config.username, config.passwd, config.options

getModels = () ->
  throw new Error "dir 'models' is not found" unless models  = utils.dirFileNames "#{dir}/models"
  models = _.chain models
    .mapObject (x) ->
      require(x)(sequelize)
    .mapObject (x) ->
      return x.definition unless x.associations
      _.each x.associations, (a, k) ->
        x.definition[k]?(a...)
      x.definition
    .value()

initHelpers = () ->
  helpers = require('./helpers').init models, configs

getControllers = () ->
  throw new Error "file 'controllers' is not found" unless controllers  = utils.dirFileNames "#{dir}/controllers"
  controllers = _.mapObject controllers, (x) ->
    require(x)(helpers.controller)

getRoutes = () ->
  throw new Error "file 'routes' is not found" unless routes  = require "#{dir}/routes"
  routes = routes helpers.route

initServer = () ->
  server = restify.createServer
    certificate: configs.server.certificate
    key: configs.server.key
    name: "myApp"
  server.use restify.queryParser()
  initRoutes()
  server

initRoutes = () ->
  _.each routes, (x) ->
    if x[0] is configs.restSignal
      _.each _.rest(x), (routeArray) ->
        handleRoute routeArray
    else handleRoute x

handleRoute = ([path, actionPath, method = "get"]) ->
  return console.warn("path #{path} mothod #{method} is unknown") unless server[method]
  recursion = (actions, controller) ->
    return [] unless controllerIn = controller[actions.shift()]
    if actions.length then recursion(actions, controllerIn) else controllerIn
  handlers = recursion(_.map(actionPath.split("."), (x) -> x.trim()), controllers)

  server[method] path, ((req, res, next) ->
    req.hooks = {}
    next()
  ), handlers...

module.exports =
  #init
  init: (_dir) ->
    dir = _dir
    #获取配置文件
    do getConfigs
    #初始化sequelize
    do getSequelizeInstance
    #获取models
    do getModels
    #初始化helpers
    do initHelpers
    #获取controllers
    do getControllers
    #获取routes
    do getRoutes
    #初始化服务
    do initServer

    {
      #instance
      sequelize: sequelize
      #server
      server: server
      #开启服务
      start: () ->
        server.listen configs.server.port
        console.log "server start at #{configs.server.port}"
      #同步数据库
      sync: () ->
        sequelize.drop().then () ->
          sequelize.sync()
    }
