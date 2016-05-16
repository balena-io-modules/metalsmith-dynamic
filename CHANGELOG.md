## 0.2.0

**Breaking**:
* `filenameToRef` signature changed: `filename -> [ ref, ext ]`
* `refToFilename` signature changed: `(ref, ext, addExt = true)`. `addExt` is `false` when `dynamic.skip_ext` is set

**Improvements**:
* no need to specify `docsExt` in the config anymore
* multiple docs extensions can be maintained automatically
* ability to generate docs without the original extension (example: `Dockerfile.tpl` -> `$distro/Dockerfile`)

## 0.1.2

* moved to a different GitHub repository

## 0.1.1

* fix syntax error

## 0.1.0

* Initial release
