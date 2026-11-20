Rebol [title: "MOBI codec CI test"]

system/options/quiet: false
system/options/log/rebol: 4

import %mobi.reb

system/options/log/mobi: 4

failed?: false
check: func[name [string!] result][
	either result [
		print [as-green "OK:" name]
	][
		print [as-purple "FAILED:" name]
		failed?: true
	]
]

print-hline
print as-yellow "Unit tests:"
decompress-palmdoc:    :system/modules/mobi/decompress-palmdoc
trailing-entries-size: :system/modules/mobi/trailing-entries-size

;; literals, including the last byte
check "palmdoc literals"    #{414243}   = copy decompress-palmdoc #{41 42 43}
check "palmdoc /part"       #{414243}   = copy decompress-palmdoc/part #{41 42 43 44} 3
check "palmdoc /part at"    #{4243}     = copy decompress-palmdoc/part next #{41 42 43 44} 2
;; 1-8 => copy following bytes as they are
check "palmdoc raw copy"    #{C1C2}     = copy decompress-palmdoc #{02 C1 C2}
;; space + char
check "palmdoc space+char"  #{2041}     = copy decompress-palmdoc #{C1}
;; length-distance pair (distance 3, length 3)
check "palmdoc pair"        #{616263616263} = copy decompress-palmdoc #{61 62 63 80 18}
;; overlapping pair (distance 1, length 5)
check "palmdoc overlap"     #{616161616161} = copy decompress-palmdoc #{61 80 0A}

check "trailing none"       0 = trailing-entries-size #{41 42 43} 3 0
check "trailing entry"      1 = trailing-entries-size #{41 42 43 81} 4 2
check "trailing 3 bytes"    3 = trailing-entries-size #{41 42 43 AA BB 83} 6 2
check "trailing multibyte"  2 = trailing-entries-size #{41 42 43 C1 01} 5 1
check "trailing both"       4 = trailing-entries-size #{41 42 43 61 01 AA 82} 7 3
check "trailing two"        2 = trailing-entries-size #{41 42 43 81 81} 5 6
check "trailing long"     130 = trailing-entries-size append append/dup #{} 0 128 #{81 02} 130 2

decode-text-record: :system/modules/mobi/decode-text-record
check-compression:  :system/modules/mobi/check-compression
check "record uncompressed" #{0102C1} = decode-text-record #{01 02 C1 FF} 3 1
check "record palmdoc"      #{2041}   = copy decode-text-record #{C1 FF} 1 2
check "compression 1 and 2" not any [error? try [check-compression 1] error? try [check-compression 2]]
check "compression HUFF"    error? try [check-compression 17480]

e: try [open [scheme: 'mobi path: %missing.mobi]]
check "open missing file"   all [error? e  e/id = 'cannot-open  e/arg1 = %missing.mobi]
e: try [open [scheme: 'mobi]]
check "open without path"   all [error? e  e/id = 'invalid-arg]

if failed? [quit/return -4]

foreach [file url] [
	%RUR.v1.mobi https://www.gutenberg.org/ebooks/13083.kindle.images
	%RUR.v2.mobi https://www.gutenberg.org/ebooks/13083.kf8.images
][
	print-hline
	if not exists? file [
		print [as-green "Downloading book from:" as-yellow url]
		try/with [
			;; Download a book for a test...
			write file read url
		][
			print as-purple "*** Failed to download a book!"
			quit/return -1
		]
	]

	print-hline
	print as-yellow "Decode the book using `decode` function:"
	try/with [
		;; Decode raw binary data already in memory...
		data: decode 'mobi file
	][
		print as-purple "*** Failed to decode a book!"
		print system/state/last-error
		quit/return -2
	]

	unless data/pdb/text-length == length? data/text [
		print as-purple ["*** Decoded text length" length? data/text "<>" data/pdb/text-length]
		quit/return -5
	]
	print as-green "MOBI data successfully decoded!"
	? data ;print to-string data/text
	
	print-hline
	print as-yellow "Decode the book using a scheme:"
	try/with [
		book: open [scheme: 'mobi path: file]
		;; all metadata should be decoded when the port is opened...
		probe info: query book object!
		check "query object!"   all [object? info  info/Name == data/name]
		check "query word"      data/name == query book 'Name
		check "query words"     (reduce [quote Name: data/name]) == query book [Name]
		check "query set-words" (reduce [quote Name: data/name]) == query book [Name:]
		check "query get-words" (reduce [data/name]) == query book [:Name]
		check "query invalid"   error? try [query book string!]
		check "query Image"     data/image == query book 'Image
		;; when text is needed, use READ on the port...
		text: read book
		? text ;print text
		close book
		;; the scheme must decode the same text as the codec
		unless text == data/text [
			print as-purple "*** Scheme text differs from the codec text!"
			quit/return -6
		]
		;; read refinements must work with the cached text
		book: open [scheme: 'mobi path: file]
		check "scheme read/part"           (copy/part data/text 100) == read/part book 100
		check "scheme read after read/part" data/text == read book
		check "scheme read/part (cached)"  (copy/part data/text 100) == read/part book 100
		check "scheme read/string (cached)" (to string! data/text) == read/string book
		;; without the full name, the name from the Palm header is used
		book/state/name: none
		check "query Name fallback" data/palm/name == query book 'Name
		close book
	][
		print as-purple "*** Failed to decode a book!"
		print system/state/last-error
		quit/return -3
	]
]
if failed? [quit/return -7]
