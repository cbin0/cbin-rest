_         = require 'underscore'
async      = require 'async'
restify   = require 'restify'
sequelize = require 'sequelize'

module.exports = (models, configs) ->

  #funcs
  getModel  = (name) -> models[name]

  pager = (req) -> (cb) ->
    {page = 1, pageSize = 10} = req.params
    offset = pageSize * (page - 1)
    limit = pageSize
    cb null, {offset, limit}

  makeWhere = (model, req) -> (cb) ->
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
          getModel[x.trim()]?
        .map (x) ->
          model: x,
          require: true
        .value()

    #删除不在model中的字段
    model.describe().then (attrs) ->
      cb null, _.omit(where, (x, attr) ->
        not attrs[attr]?
      )

  #查询数据库，返回一个aync的done函数
  query = (hook, req, res, next, exec) -> (err, results) ->
    return next err if err?
    promise = exec(results)
    promise.then((result) ->
      return next result if result.constructor is Error
      req.hooks[hook] = result
      next()
    ).catch (err) ->
      next err

  model: (name, hook = name) -> (req, res, next) ->
    model = getModel name
    unless model
      next new restify.errors.InternalServerError 'server error'
    else
      req.hooks[hook] = model
      next()

  one: (hook) -> (req, res, next) ->
    model = req.hooks[hook]
    id = req.params.id
    query hook, res, next, () -> model.findOne id

  list: (hook) -> (req, res, next) ->
    model = req.hooks[hook]
    async.parallel {
      pager: pager req
      where: makeWhere model, req
    }, query hook, req, res, next, (results) ->
      model.findAndCountAll
        where: results.where
        offset: results.pager.offset
        limit: results.pager.limit

  save: (hook) -> (req, res, next) ->
    model = req.hooks[hook]
    query hook, req, res, next, () -> model.build(req.params).save()

  patch: (hook) -> (req, res, next) ->
    model = req.hooks[hook]
    model.findOne(req.params.id).then (instance) ->
      return next new restify.errors.NotFoundError unless instance
      _.extend instance, _.omit(req.params, "id")
      query hook, req, res, next, () -> instance.save()

  delete: (hook) -> (req, res, next) ->
    return

  json: (hook) -> (req, res, next) ->
    res.json req.hooks[hook]
    res.end()
