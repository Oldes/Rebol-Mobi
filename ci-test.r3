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
;; invalid pairs (distance 0, distance past the start of the output)
check "palmdoc distance 0"  error? try [decompress-palmdoc #{61 80 00}]
check "palmdoc distance >"  error? try [decompress-palmdoc #{61 80 10}]

compress-palmdoc: :system/modules/mobi/compress-palmdoc
round-trip?: func[data][data == copy decompress-palmdoc compress-palmdoc data]
check "compress space+char" #{C1}           = compress-palmdoc #{20 41}
check "compress pair"       #{61626380 18}  = compress-palmdoc #{61 62 63 61 62 63}
check "compress overlap"    #{61800F 6161}  = compress-palmdoc #{61616161616161616161616161}
check "compress raw bytes"  #{03 80 C1 01 41} = compress-palmdoc #{80 C1 01 41}
check "compress empty"      round-trip? #{}
check "compress text"       round-trip? to binary! {<p>Příliš žluťoučký kůň úpěl ďábelské ódy. Příliš žluťoučký!</p>}
random/seed 1
ok: true
loop 50 [
	b: make binary! 4096
	loop random 4096 [append b -1 + random 256]
	unless round-trip? b [ok: false]
	b: make binary! 4096
	loop random 4096 [append b pick "ab c dE" random 7]
	unless round-trip? b [ok: false]
]
check "compress random"     ok

check "trailing none"       0 = trailing-entries-size #{41 42 43} 3 0
check "trailing entry"      1 = trailing-entries-size #{41 42 43 81} 4 2
check "trailing 3 bytes"    3 = trailing-entries-size #{41 42 43 AA BB 83} 6 2
check "trailing multibyte"  2 = trailing-entries-size #{41 42 43 C1 01} 5 1
check "trailing both"       4 = trailing-entries-size #{41 42 43 61 01 AA 82} 7 3
check "trailing two"        2 = trailing-entries-size #{41 42 43 81 81} 5 6
check "trailing long"     130 = trailing-entries-size append append/dup #{} 0 128 #{81 02} 130 2

record-span: :system/modules/mobi/record-span
recs: [0 0 0  100 0 1  150 0 2]
check "record span"         [100 50] = record-span recs 1
check "record span first"   [0 100]  = record-span next recs 0
check "record span last"    none? record-span recs 2  ;; no following record
check "record span none"    none? record-span recs 0#FFFFFFFF
check "record span negative" none? record-span recs -1
check "record span no index" none? record-span recs none

read-mobi-header: :system/modules/mobi/read-mobi-header
hdr: binary 252
repeat i 63 [binary/write hdr [ui32 :i]] ;; 252 bytes of UI32 values 1, 2, 3...
hdr: hdr/buffer
m: read-mobi-header hdr 260
check "mobi header full"   all [m/type = 1  m/indx-index = 56  m/boundary-offset = 63]
m: read-mobi-header copy/part hdr 220 228
check "mobi header 228"    all [m/srcs-index = 51  none? m/indx-index  none? m/boundary-offset]
m: read-mobi-header copy/part hdr 108 116
check "mobi header 116"    all [m/exth-flags = 27  none? m/unknown-1  none? m/srcs-index  m/extra-flags = 0]

cover-index: :system/modules/mobi/cover-index
mobi: object [image-index: 5]
check "cover index"         7 = cover-index mobi [201 Coveroffset 2]
check "cover first image"   5 = cover-index mobi [100 Author "x"]
check "cover no EXTH"       5 = cover-index mobi none
check "cover no offset"     5 = cover-index mobi [201 Coveroffset 0#FFFFFFFF]
check "cover no image"      none? cover-index object [image-index: 0#FFFFFFFF] [201 Coveroffset 2]
check "cover no MOBI"       none? cover-index none none

decode-text: :system/modules/mobi/decode-text
check "decode-text CP1252"  "€é" == decode-text #{80E9} 1252
check "decode-text UTF-8"   "€é" == decode-text #{E282AC C3A9} 65001
check "decode-text default" "€é" == decode-text #{E282AC C3A9} none
read-exth-header: :system/modules/mobi/read-exth-header
exth: binary 14
binary/write exth [UI32 100 UI32 14 BYTES #{4175746F7280}] ;; Author: "Autor€" in CP1252
check "EXTH CP1252"  [100 Author "Autor€"] = read-exth-header exth/buffer 1 1252

decode-text-record: :system/modules/mobi/decode-text-record
check-compression:  :system/modules/mobi/check-compression
check "record uncompressed" #{0102C1} = decode-text-record #{01 02 C1 FF} 3 1
check "record palmdoc"      #{2041}   = copy decode-text-record #{C1 FF} 1 2
check "compression 1 and 2" not any [error? try [check-compression 1] error? try [check-compression 2]]
check "compression HUFF"    error? try [check-compression 17480]
check-encryption:   :system/modules/mobi/check-encryption
check "no encryption"       not error? try [check-encryption 0]
check "encryption"          all [error? try [check-encryption 1] error? try [check-encryption 2]]

e: try [open [scheme: 'mobi path: %missing.mobi]]
check "open missing file"   all [error? e  e/id = 'cannot-open  e/arg1 = %missing.mobi]
e: try [open [scheme: 'mobi]]
check "open without path"   all [error? e  e/id = 'invalid-arg]

;; minimal plain PalmDOC file (no MOBI header): record 0, one text record and an end record
plain: append/dup #{} 0 32
change plain "Synth"
binary/write tmp: copy #{} [
	UI16 0 UI16 0 UI32 0 UI32 0 UI32 0 UI32 0 UI32 0 UI32 0
	BYTES #{54455874} BYTES #{52454164} UI32 0 UI32 0 UI16 3 ;; TEXt REAd, 3 records
	UI32 104 UI32 0  UI32 120 UI32 1  UI32 125 UI32 2  UI16 0
	UI16 1 UI16 0 UI32 5 UI16 1 UI16 4096 UI32 0#00020000 ;; uncompressed, 5 bytes in 1 record, reading position (not encryption!)
	BYTES #{48656C6C6F} BYTES #{E98E0D0A}        ;; "Hello" + end record
]
append plain tmp
write %plain-test.pdb plain
e: try [data: decode 'mobi %plain-test.pdb]
check "plain PalmDOC codec"  all [not error? e  "Hello" == to string! data/text  none? data/mobi]
e: try [book: open [scheme: 'mobi path: %plain-test.pdb]]
check "plain PalmDOC scheme" all [not error? e  "Hello" == read/string book  "Synth" == query book 'Name]
try [close book]
delete %plain-test.pdb

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
