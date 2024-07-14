[![Rebol-Mobi CI](https://github.com/Oldes/Rebol-Mobi/actions/workflows/main.yml/badge.svg)](https://github.com/Oldes/Rebol-Mobi/actions/workflows/main.yml)
[![Gitter](https://badges.gitter.im/rebol3/community.svg)](https://app.gitter.im/#/room/#Rebol3:gitter.im)

# Rebol/Mobi

MobiPocket/Kindle eBook `mobi` file codec for the [Rebol](https://github.com/Oldes/Rebol3) (version 3.11.0 and newer) programming language.

# Usage example

Import the module like:
```
import %mobi.reb ;; or just `mobi if the module is installed in the standard modules location
```

Than the simplest way to decode everything the decoder is capable of handling:
```rebol
data: load %path/to/book.mobi
```

Instead of trying to decode everything as in the code above, it is possible to use a `mobi` scheme:
```rebol
;; open a mobi port:
book: open [scheme: 'mobi path: %path/to/book.mobi]

;; get all metadata:
meta: query book

;; get complete text:
text: read/string book

;; close port when not needed!
close book
```

![Screenshot](https://matrix-client.matrix.org/_matrix/media/v3/download/matrix.org/besDNKhrvpGvkhkgFckPifoG?allow_redirect=true)
