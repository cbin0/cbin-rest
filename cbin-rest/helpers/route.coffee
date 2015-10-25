module.exports = (models, configs) ->
  rest: (model, controller = model) ->
    [
      configs.restSignal
      ["#{model}s", "#{controller}.list", 'get']
      ["#{model}s/:id", "#{controller}.get", 'get']
      ["#{model}s/:id", "#{controller}.post", 'post']
      ["#{model}s/:id", "#{controller}.delete", 'del']
    ]
