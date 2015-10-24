restify   = require 'restify'
sequelize = require 'sequelize'

models = {}
routes = {}
configs = {}

#funcs
getModel  = do ->
  (name) -> _models[name]

pager     = (req) ->
  page = req.params.page
  pageSize = req.params.pagesize
  offset = pageSize * (page - 1)
  limit = pageSize
  return [offset, limit]

makeWhere = (model, req) ->
  where =
    isDeleted: no
  #attributes
  if req.params.attributes
    where.attributes = _.chain(req.params.attributes.split ",")
      .filter (x) ->
        model[x] isnt undefined
      .value()
  #include
  if req.params.include
    where.include = _.chain(req.params.include.split ",")
      .filter (x) ->
        getModel[x.trim()] isnt undefined
      .map (x) ->
        model: x,
        require: true
      .value()
  where

handlePromise = (promise, hook, res, next) ->
  promise.then((result) ->
    return next result if result.constructor is Error
    res.hooks[hook] = result
  ).catch (err) ->
    next err

forExports =
  rest: (name) ->
    [
      configs.restSignal
      "#{name}s", [
        @model name
        @list name
        @json name
      ], 'get'
      "#{name}s", [
        @model name
        @save name
        @json name
      ], 'post'
      "#{name}/:id", [
        @model name
        @one name
        @json name
      ], 'patch'
    ]

  model: (name, hook = name) -> (req, res, next) ->
    model = getModel name
    unless model
      next new restify.errors.InternalServerError 'server error'
    else
      req.hooks[hook] = require model

  one: (hook, hookRes = hook) -> (req, res, next) ->
    where = makeWhere req
    model = req.hooks[hook]
    id = req.params.id
    handlePromise model.findOne(id), hookRes, res, next

  list: (hook, hookRes = hook) -> (req, res, next) ->
    [offset, limit] = pager req
    where = makeWhere req
    model = req.hooks[hook]
    handlePromise model.findAndCountAll(
       where: where
       offset: offset
       limit: limit
     ), hookRes, res, next

  save: (hook, hookRes = hook) -> (req, res, next) ->
    model = req.hooks[hook]
    handlePromise model.build(req.params).save(), hookRes, res, next

  json: (hook) -> (req, res, next) ->
    res.json res.hooks[hook]
    res.end()

module.exports =

  init: (_models, _routes, _configs) ->
    models = _models
    routes = _routes
    configs = _configs

  forExports: forExports
