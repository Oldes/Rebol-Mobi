[![rebol-mobi](https://github.com/user-attachments/assets/75a35850-71ca-45ce-a3d2-8cafff440a47)](https://github.com/Oldes/Rebol-Mobi)

[![Rebol-Mobi CI](https://github.com/Oldes/Rebol-Mobi/actions/workflows/main.yml/badge.svg)](https://github.com/Oldes/Rebol-Mobi/actions/workflows/main.yml)
[![Gitter](https://badges.gitter.im/rebol3/community.svg)](https://app.gitter.im/#/room/#Rebol3:gitter.im)
[![Zulip](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://rebol.zulipchat.com/)


# Rebol/Mobi

MobiPocket/Kindle eBook `mobi` file codec and scheme for the [Rebol](https://github.com/Oldes/Rebol3) (version 3.16.0 and newer) programming language.

## Supported

* MOBI files (`.mobi`, `.azw`) and plain PalmDOC files without a MOBI header
* PalmDOC compressed or uncompressed text
* UTF-8 and CP1252 text encoding
* metadata from the EXTH header (author, publisher, description, ISBN...)
* cover image (decoded when a matching image codec is available: JPEG, PNG or GIF)

Not supported (an error is thrown when decoding the text):
* HUFF/CDIC compression
* DRM encrypted books

## Usage

Import the module like:
```rebol
import %mobi.reb ;; or just `import mobi` if the module is installed in the standard modules location
```

### Codec

The simplest way is to decode everything the decoder is capable of handling:
```rebol
data: load %path/to/book.mobi
;; or (also for files without a registered suffix):
data: decode 'mobi %path/to/book.mobi
```
The result is an object with these fields:

| Field     | Content                                                   |
|-----------|-----------------------------------------------------------|
| `name`    | full name of the book                                     |
| `text`    | complete decompressed text as `binary!` (usually HTML)    |
| `exth`    | EXTH metadata as a block of `[type name value]` triplets  |
| `image`   | cover image (if decoded)                                  |
| `palm`    | Palm database header                                      |
| `pdb`     | PalmDOC header (compression, text length...)              |
| `mobi`    | MOBI header (`none` for plain PalmDOC files)              |
| `records` | list of the PDB records                                   |
| `srcs`    | embedded source archive (if present)                      |

To get the text as a string, use `to string! data/text` (for CP1252 books `iconv data/text 1252`).

### Scheme

Instead of decoding everything at once, it is possible to use the `mobi` scheme.
Only the headers are read when the port is opened; the text and the image are decoded on demand.
```rebol
;; open a mobi port:
book: open [scheme: 'mobi path: %path/to/book.mobi]

;; get all metadata as an object:
meta: query book object!

;; get a single field:
author: query book 'Author

;; get selected fields:
query book [Name Author]   ;== [Name: "..." Author: "..."]
query book [:Name :Author] ;== ["..." "..."] (values only)

;; get the cover image:
image: query book 'Image

;; get the complete text (decoded text is cached in the port):
text: read/string book

;; get only the beginning of the text (stops decompressing early):
intro: read/part book 1000

;; close port when not needed!
close book
```
Repeated EXTH records (for example more authors) are collected in a block when queried with `object!`;
querying a single field returns only the first one.

## Tests

Run the CI test script (it downloads two books from Project Gutenberg):
```
r3 ci-test.r3
```

![Screenshot](https://matrix-client.matrix.org/_matrix/media/v3/download/matrix.org/besDNKhrvpGvkhkgFckPifoG?allow_redirect=true)
