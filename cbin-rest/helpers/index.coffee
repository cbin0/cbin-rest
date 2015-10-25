Controller  = require('./controller')
Route       = require('./route')

module.exports =
  new: (models, configs) ->
    controller: new  Controller(models, configs)
    route: new  Route(models, configs)
