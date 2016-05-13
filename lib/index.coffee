path = require('path')
_ = require('lodash')

Dicts = require('./dictionaries')
util = require('./util')

{ replacePlaceholders, tokenize, applyFn } = util
tokenize = applyFn(tokenize)

expand = (files, options) ->
  dicts = Dicts(options.dictionaries)
  { docsExt, refToFilename, filenameToRef } = options
  refToFilename ?= util.refToFilename
  filenameToRef ?= util.filenameToRef

  buildSingleDoc = (templateObj, dynamicMeta, variablesContext) ->
    { ref: refFormat } = dynamicMeta

    refTemplate = replacePlaceholders(refFormat, {
      $original_ref: templateObj.$original_ref
    })

    extendedVariablesContext = _.assign({}, variablesContext, {
      $original_ref: templateObj.$original_ref
    })

    populate = applyFn(replacePlaceholders, extendedVariablesContext)

    obj = _.assign({}, templateObj, {
      $dictionaries: dicts
      $variables: variablesContext
      $ref_template: refTemplate
    })

    if options.populateFields
      for key in options.populateFields
        obj[key] = populate(dynamicMeta[key])

    if options.tokenizeFields
      for key in options.tokenizeFields
        obj[key] = tokenize(dynamicMeta[key])

    key = refToFilename(populate(refTemplate), docsExt)
    return { "#{key}": obj }

  buildDocsRec = (templateObj, dynamicMeta, variablesContext, remainingVariables) ->
    if not remainingVariables?.length
      return buildSingleDoc(templateObj, dynamicMeta, variablesContext)

    result = {}
    [ nextVariable, remainingVariables... ] = remainingVariables
    if nextVariable?[0] isnt '$'
      throw new Error("Variable name must start with $ sign \"#{nextVariable}\".")

    nextVariableDict = dicts.getDict(nextVariable)
    if not nextVariableDict
      throw new Error("Unknown dictionary \"#{nextVariable}\".")
    templateObj["#{nextVariable}_dictionary"] = nextVariableDict

    for details in nextVariableDict
      nextVariableId = details.id
      nextTemplateObj = _.assign({}, templateObj, {
        "#{nextVariable}_id": nextVariableId
        "#{nextVariable}": details
      })
      nextContext = _.extend({}, variablesContext, {
        "#{nextVariable}": nextVariableId
      })

      _.assign(result, buildDocsRec(
        nextTemplateObj,
        dynamicMeta,
        nextContext,
        remainingVariables
      ))

    return result

  buildDynamicDoc = (file, templateObj) ->
    console.log("Expanding dynamic doc #{file}")
    originalRef = filenameToRef(file, docsExt)
    templateObj = _.assign({ $original_ref: originalRef }, templateObj)
    dynamicMeta = _.assign({}, templateObj.dynamic)

    { variables: variablesNames, ref: refFormat } = dynamicMeta
    if not variablesNames
      throw new Error("No variables defined for the dynamic doc #{file}.")
    if not refFormat
      throw new Error("No ref format defined for the dynamic doc #{file}.")

    return buildDocsRec(templateObj, dynamicMeta, {}, variablesNames)

  for file of files
    obj = files[file]
    if not obj.dynamic
      continue
    delete files[file]
    _.assign(files, buildDynamicDoc(file, obj))


plugin = (options = {}) ->
  return (files, metalsmith, done) ->
    expand(files, options)
    done()

plugin.util = util
plugin.Dicts = Dicts

module.exports = plugin
