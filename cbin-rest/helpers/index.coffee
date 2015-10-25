module.exports =
  init: (models, configs) ->
    controller: require('./controller')(models, configs)
    route: require('./route')(models, configs)
