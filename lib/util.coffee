path = require('path')
_ = require('lodash')

exports.replacePlaceholders = (arg, context) ->
  for key, value of context
    re = new RegExp(_.escapeRegExp(key), 'g')
    arg = arg.replace(re, value)
  return arg

exports.filenameToRef = (filename) ->
  ext = path.extname(filename)
  if ext
    filename = filename[0...filename.length - ext.length]
  return [ filename, ext ]

exports.refToFilename = (ref, ext, addExt = true) ->
  return ref if not (addExt and ext)
  return "#{ref}#{ext}"

exports.applyFn = (fn, fnArgs...) ->
  return (arg) ->
    return arg if not arg
    partialFn = _.partial(fn, _, fnArgs...)

    if _.isArray(arg)
      return _.map(arg, partialFn)
    else if _.isObject(arg)
      return _.mapValues(arg, partialFn)
    else if _.isString(arg)
      return partialFn(arg)

exports.tokenize = (text) ->
  return if not text
  result = []
  start = 0
  re = /\$[\w_]+/g
  while match = re.exec(text)
    result.push(text.substring(start, match.index).trim())
    result.push(match[0])
    start = match.index + match[0].length
  remainingText = text.substring(start).trim()
  result.push(remainingText) if remainingText
  return result
