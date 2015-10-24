_    = require 'underscore'

module.exports =
  #读取目录下的文件夹，忽略文件
  dirDirNames: (dir) ->
    stat = fs.statSync dir
    res = {}
    return res if stat.isFile()
    dirs = fs.readdirSync dir
    _.each dirs, (x, i) ->
      statX = fs.statSync x
      files[x] = "#{dir}/#{x}" unless statX.isFile()
    res

  #读取目录下的文件，忽略文件夹
  dirFileNames: (dir) ->
    stat = fs.statSync dir
    files = {}
    return {} if stat.isFile()
    dirs = fs.readdirSync dir
    _.each dirs, (x, i) ->
      statX = fs.statSync x
      files[x] = "#{dir}/#{x}" if statX.isFile()
    res
