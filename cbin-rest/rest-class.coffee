_             = require 'underscore'
restify       = require 'restify'
Sequelize     = require 'Sequelize'
utils         = require './utils'

class CRest

  constructor: (@dir, configs) ->

    #获取配置文件
    @configs =  do =>
      throw new Error "file 'configs' is not found" unless _configs = require "#{@dir}/configs"
      _.extend {}, _configs, configs
    #初始化sequelize
    @sequelize = do  =>
      config = @configs.db
      new Sequelize config.database, config.username, config.passwd, config.options
    #获取models
    @models = do =>
      throw new Error "dir 'models' is not found" unless models  = utils.dirFileNames "#{@dir}/models"
      _.chain models
        .mapObject (x) =>
          require(x)(@sequelize)
        .mapObject (x) =>
          return x.definition unless x.associations
          _.each x.associations, (a, k) ->
            x.definition[k]?(a...)
          x.definition
        .value()
    #初始化helpers
    @helpers = do =>
      require('./helpers').new @models, @configs
    #获取controllers
    @controllers = do =>
      throw new Error "file 'controllers' is not found" unless controllers  = utils.dirFileNames "#{@dir}/controllers"
      _.mapObject controllers, (x) =>
        require(x)(@helpers.controller)
    #获取routes
    @routes = do =>
      throw new Error "file 'routes' is not found" unless routes  = require "#{@dir}/routes"
      routes @helpers.route
    #初始化服务
    @server = do =>
      server = restify.createServer
        certificate: @configs.server.certificate
        key: @configs.server.key
        name: "myApp"
      server.use restify.queryParser()
      server
    #初始化routes
    do =>
      handleRoute = ([path, actionPath, method = "get"]) =>
        return console.warn("path #{path} mothod #{method} is unknown") unless @server[method]
        recursion = (actions, controller) ->
          return [] unless controllerIn = controller[actions.shift()]
          if actions.length then recursion(actions, controllerIn) else controllerIn
        handlers = recursion(_.map(actionPath.split("."), (x) -> x.trim()), @controllers)

        @server[method] path, ((req, res, next) ->
          req.hooks = {}
          next()
        ), handlers...

      _.each @routes, (x) =>
        if x[0] is @configs.restSignal
          _.each _.rest(x), (routeArray) ->
            handleRoute routeArray
        else handleRoute x



  start: () ->
    return unless @server
    @server.listen @configs.server.port

  sync: () ->
    return unless @sequelize
    @sequelize.drop().then () =>
      @sequelize.sync()

module.exports  = CRest
