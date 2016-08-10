assert = require('assert')
_ = require('lodash')
plugin = require('../lib')

dicts = new plugin.Dicts
  $a: [
    { id: 'a1' }
    { id: 'a2' }
    { id: 'a3' }
  ]
  $b: [
    { id: 'b1' }
    { id: 'b2' }
    { id: 'b3' }
  ]

console.log '== Test simple dicts =='

assert.deepEqual(dicts.dictNames, [ '$a', '$b' ])



console.log '== Test dicts FKs =='

dictsWithExpansion = new plugin.Dicts
  $a: [
    { id: 'a1', $my_b: '$b.b1' }
    { id: 'a2', $my_b: '$b.b2' }
    { id: 'a3', $my_b: '$b.b3' }
  ]
  $b: [
    { id: 'b1', name: 'b1' }
    { id: 'b2', name: 'b2' }
    { id: 'b3', name: 'b3' }
  ]

assert.deepEqual(dictsWithExpansion.getDetails('$a', 'a1').$my_b,
  dictsWithExpansion.getDetails('$b', 'b1'))
assert.deepEqual(dictsWithExpansion.getDetails('$a', 'a2').$my_b,
  dictsWithExpansion.getDetails('$b', 'b2'))
assert.deepEqual(dictsWithExpansion.getDetails('$a', 'a3').$my_b,
  dictsWithExpansion.getDetails('$b', 'b3'))



console.log '== Test dicts with circular FKs =='

dictsWithExpansion = new plugin.Dicts
  $a: [
    { id: 'a1', $my_b: '$b.b1' }
    { id: 'a2', $my_b: '$b.b2' }
  ]
  $b: [
    { id: 'b1', $my_a: '$a.a1' }
    { id: 'b2', $my_a: '$a.a2' }
  ]

assert.deepEqual(dictsWithExpansion.getDetails('$b', 'b1').$my_a,
  dictsWithExpansion.getDetails('$a', 'a1'))
assert.deepEqual(dictsWithExpansion.getDetails('$a', 'a2').$my_b,
  dictsWithExpansion.getDetails('$b', 'b2'))



console.log '== Test basic expansion =='

files = {
  'path/to/file':
    dynamic:
      variables: [ '$a' ]
      ref: '$a'
}

plugin(dictionaries: dicts)(files, null, ->)

assert.ok(files['a1'])
assert.ok(files['a2'])
assert.ok(files['a3'])
assert.equal(files['a1'].$a.id, 'a1')


console.log '== Test multiple variables =='

files = {
  'path/to/file':
    dynamic:
      variables: [ '$a', '$b' ]
      ref: '$a/$b'
}

plugin(dictionaries: dicts)(files, null, ->)

assert.ok(files['a1/b2'])
assert.ok(files['a2/b3'])
assert.ok(files['a3/b1'])

assert.equal(files['a2/b3'].$a_id, 'a2')
assert.equal(files['a2/b3'].$b_id, 'b3')



console.log '== Test with original ref =='

files = {
  'my_file':
    dynamic:
      variables: [ '$a', '$b' ]
      ref: '$a/$original_ref/$b'
}

plugin(dictionaries: dicts)(files, null, ->)

assert.ok(files['a2/my_file/b3'])

assert.equal(files['a2/my_file/b3'].$a_id, 'a2')
assert.equal(files['a2/my_file/b3'].$b_id, 'b3')



console.log '== Test with original ref and extension =='

files = {
  'my_file.txt':
    dynamic:
      variables: [ '$a', '$b' ]
      ref: '$a/$b/$original_ref'
}

plugin(dictionaries: dicts)(files, null, ->)

assert.ok(files['a2/b3/my_file.txt'])

assert.equal(files['a2/b3/my_file.txt'].$a_id, 'a2')
assert.equal(files['a2/b3/my_file.txt'].$b_id, 'b3')



console.log '== Test with original ref and skip_ext =='

files = {
  'my_file.txt':
    dynamic:
      variables: [ '$a', '$b' ]
      ref: '$a/$b/$original_ref'
      skip_ext: true
}

plugin(dictionaries: dicts)(files, null, ->)

assert.ok(files['a2/b3/my_file'])

assert.equal(files['a2/b3/my_file'].$a_id, 'a2')
assert.equal(files['a2/b3/my_file'].$b_id, 'b3')



console.log '== Test with static fragment =='

files = {
  'my_file.txt':
    dynamic:
      variables: [ '$a', '$b' ]
      ref: 'prefix/$a/$b/$original_ref'
      skip_ext: true
}

plugin(dictionaries: dicts)(files, null, ->)

assert.ok(files['prefix/a2/b3/my_file'])

assert.equal(files['prefix/a2/b3/my_file'].$a_id, 'a2')
assert.equal(files['prefix/a2/b3/my_file'].$b_id, 'b3')


console.log 'Done OK'
