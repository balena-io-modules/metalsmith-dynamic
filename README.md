Metalsmith dynamic documents plugin
======================

> Turn a dynamic document template into concrete pages interpolated over a set of variables

## How does Metalsmith work

Metalsmith reads all files from a given directory and passes them through a set of transformations. These transformations can change the file's contents, path/name/extension, render templates, delete files or create new. Finally the documents are getting written to a different directory.

## How does this plugin work

This plugins looks for the documents marked as `dynamic` in their front-matter. Each document should specify a set of dynamic variables. The plugin removes the original template document from the metalsmith set and injects new documents for each and every combination of variables values.

## Isn't it too simplistic?

The idea is simple yet powerful. Combined with other tools (like Handlebars templates and a couple of helpers) one can, for example, manage a big set of documents that share common structure but have different bits, and keep the things DRY and maintainable.

For example, at Resin.io we manage documents for tens of different device types and several programming languages. For each combination there's a page on our site (https://docs.resin.io/getting-started). Some blocks are identical across them, and some are specific to the board type, or the language, or even their combination.

So we've created [doxx](https://github.com/resin-io-projects/doxx) engine, and this plugin is one of its core components.

## How to use it

### Glossary

**Ref**. Metalsmith reads all files from a given source directory, say `src/`.
Having the file `src/a/path/to/file.ext` we call it's path without the source directory and an extension a `ref`. So in this example the ref is `a/path/to/file`. There could be cases when you need more complex rules, for example when rendering Markdown to HTML files with permalinks the `src/index.md` file is rendered as `dest/index.html`, while any other `src/somefile.md` is rendered as `dest/somefile/index.html`. See the **API** section below for details how to configure this behavior.

> Why do we need this? When expanding the file over a set of variables we have to build the path for the newly injected files. Usually it's based on the original file path and variables values. Given the source file is `src/intro.md`, and having a single variable called `$language` you probably want the new files to be called like `src/intro-$language.md`, and not `src/intro.md-$language`.

To expand the dynamic document you define **Variables**. Each `variable` matches a `dictionary` (currently only 1 variables can match each dictionary). When the document is expanded each `variable` is iterated over all the entries in the given dictionary.

**Dictionary** is a named set of data. Technically each `dictionary` is an array of objects. Each object must have an `id` property (unique in the given dictionary) and can have any additional arbitrary properties. The first entry in the dictionary is considered `default`.

**Population** of a string is the process of replacing variable placeholders with their specific values (`id`s from the corresponding dictionary).

Sometimes you may also need a string to be **tokenized**. It's easier to explain with an example:

`Get started with $os and $language.` is tokenized into an array:
`[ 'Get started with', '$os', 'and', '$language', '.' ]`.

The odd elements always correspond to the plain strings (1-based, the first item will be empty string if the original string starts with the placeholder), the even are placeholders. The last plain string item (`'.'` in the example above) will only be present if it's non-empty. Plain string items are trimmed.

This can be useful for building dynamic UI with drop-downs in place of variables placeholders, as we do for resin.io docs.

### What essentially does it do

The plugin will go over all files in your Metalsmith tree.

It will look for those having `dynamic` key defined in their front-matter. The files that don't have it are left intact.

Dynamic docs must define two properties under the dynamic key:

```
---
dynamic:
  variables: [ $a, $b ]
  ref: $original_ref/$a/$b
---
```

Each variable name must start from the `$` sign. Each variable name must be equal to a name of the `dictionary`.

The plugin does this:

* sets `$original_ref` to the `ref` of the original file,
* removes this file from the tree and uses it as a template,
* goes over each possible value for each of the variables (so if there are 2 entries in the dictionary `$a` and 5 entires in the dictionary `$b` there will be 10 possible combinations),
* for each combination computes the `ref` for the new file by populating the `ref` format (with `$original_ref` and the values of the variables),
* computes the new file path: `ref + config.docsExt` (see below for configuration options),
* builds a new file object that has all the information from the original template file (including the content being left intact) extended with the following new properties:

  * `$original_ref` as defined above,
  * `$dictionaries` - the `Dicts` object built from the `config.dictionaries` (see **API** for details),
  * `$variables` - a key-value hash of the variables values for the chosen combination
  * `$ref_template` the `ref` from the document front-matter, with `$original_ref` replaced
  * for each variable `$X`:

    * `$X_id` — the value (`id`) of the variable for this specific file,
    * `$X` - the entire object from dictionary corresponding to this `id`,
    * `$X_dictionary` - the full dictionary corresponding to this variable,

* injects this new object into the tree with the file path computed above.

### API

The basic usage of the plugin is:

```
var Metalsmith = require('metalsmith')
var dynamic = require('metalsmith-dynamic')

Metalsmith(__dirname)
.source('src')
.destination('dst')
.use(dynamic({
  dictionaries: __dirname + 'dicts'
  docsExt: 'md'
}))
```

In this example it will find all the `dynamic` files, automatically read dictionaries from the `dicts` directory, and compute new paths properly maintaining the `.md` extension.

#### Options

##### `dictionaries`, **required**.

Can be one of:

- a string (path to the directory),
- a hash object,
- an existing `Dicts` object (see below).

When it's a string the plugin will auto-discover dictionaries in the specified directory. Only `.js`, `.json`, and `.coffee` files are read. `JSON` files must contain an array of objects. `JS` or `CoffeeScript` files must be valid CommonJS modules that export such array. Each `dir/file.ext` dictionary is automatically named as `$file` (the dollar sign is auto-added).

When it's a hash object it's keys are dictionary names (and must start with `$`), and values should be arrays.

Existing `Dicts` object is left intact.

##### `docsExt`, _optional_.

The extension (_without_ the dot) of the source files.

If specified it will be stripped from the filename when calculating `$original_ref`, and added to the `ref` to compute the name of the resultant expanded document. See `refToFilename`, `filenameToRef` for more info.

##### `populateFields`, _optional_.

An array of fields to populate. For each `field` in this list we essentially do
`file[field] = populate(file.dynamic[field])`.

##### `tokenizeFields`, _optional_.

An array of fields to tokenize. For each `field` in this list we essentially do
`file[field] = tokenize(file.dynamic[field])`.

#### `refToFilename`, `filenameToRef`, _optional_.

These methods can be passed to customize the way how filenames are converted to refs and vice versa.

#### Dicts

`dynamic.Dicts` is a constructor (can be used with or without `new`) that wraps a set of dictionaries. It can be called with either a path to dictionaries directory, a hash of `$name -> [values]` structure, or an existing `Dicts` object (which will be returned intact).

The instance has the following properties and methods:

##### `dictNames`
An array with all the dictionaries names.

##### `getDict(key)`
Returns all the entries (an array) for the given dictionary.

##### `getValues(key)`
Returns all the `id`s (an array) for the given dictionary.

##### `getDetails(key, id)`
Returns the entire object for the given `id` in the given dictionary.

##### `getDefault(key)`
Returns the `id` of the first entry in the given dictionary.

##### `getDefaults()`
Returns all the default `id`s (as a hash) for all the dictionaries.

#### Util

`dynamic.util` stores utility functions used by the plugin.

##### `util.refToFilename(ref, ext)`
Default implementation, adds `.ext` to the `red`.

##### `util.filenameToRef(file, ext)`
Default implementation, remove `.ext` from the `file`.

##### `util.replacePlaceholders(str, context)`
Populates the string using the provided context (key-value hash).

##### `util.tokenize(str)`
Returns an array with string tokens (see above for explanation).


License
-------

The project is licensed under the Apache 2.0 license.
