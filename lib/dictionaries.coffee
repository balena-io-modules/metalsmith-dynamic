fs = require('fs')
path = require('path')
_ = require('lodash')

Dicts = (dictionaries) ->
  if dictionaries instanceof Dicts
    return dictionaries

  if _.isString(dictionaries)
    return Dicts.fromDir(dictionaries)

  if this not instanceof Dicts
    return new Dicts(dictionaries)

  @_dicts = _.assign({}, dictionaries)
  @dictNames = _.keys(@_dicts)

  return

Dicts::getDict = (key) ->
  @_dicts[key]

Dicts::getValues = (key) ->
  _.map @_dicts[key], 'id'

Dicts::getDetails = (key, id) ->
  _.find @getDict(key), { id }

Dicts::getDefault = (key) ->
  _.first(@getDict(key))?.id

Dicts::getDefaults = ->
  result = {}
  for key in @dictNames
    result[key] = @getDefault(key)
  return result

KNOWN_EXTS = [
  'js'
  'coffee'
  'json'
]

Dicts.fromDir = (dir) ->
  if dir
    extsRe = new RegExp("\\.(#{KNOWN_EXTS.join('|')})$")
    files = fs.readdirSync(dir)
      .filter (file) -> file.match(extsRe)
      .map (file) ->
        ext = path.extname(file)
        return path.basename(file, ext)
  else
    files = []

  dicts = {}
  for file in files
    dicts["$#{file}"] = require("#{dir}/#{file}")

  return Dicts(dicts)

module.exports = Dicts
