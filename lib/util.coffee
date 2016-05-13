_ = require('lodash')

exports.replacePlaceholders = (arg, context) ->
  for key, value of context
    re = new RegExp(_.escapeRegExp(key), 'g')
    arg = arg.replace(re, value)
  return arg

exports.refToFilename = (ref, ext) ->
  return ref if not ext
  return "#{ref}.#{ext}"

exports.filenameToRef = (filename, ext) ->
  return filename if not ext
  extRe = new RegExp("\\.#{ext}$")
  ref = filename.replace(extRe, '')
  return ref

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
