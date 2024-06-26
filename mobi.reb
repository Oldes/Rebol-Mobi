Rebol [
	Title:  "Codec: MOBI"
	Type:    module
	Name:    mobi
	Date:    25-Jun-2024
	Version: 0.0.1
	Author:  @Oldes
	Home:    https://github.com/Oldes/Rebol-Mobi
	Rights:  MIT
	Purpose: {Decode information from MOBI ebook files}
	History: [
		25-Jun-2024 @Oldes {Initial version}
	]
	Notes: {
		The MOBI file format is closed source, so there is no public documentation.
		I used these sources to figure out what is known about it:
		* https://wiki.mobileread.com/wiki/MOBI
		* https://metacpan.org/dist/EBook-Tools/source/lib/EBook/Tools/PalmDoc.pm
		* https://github.com/ywzhaiqi/MyKindleTools/tree/master/kindleunpack
	}
	Needs: 3.11.0 ;; used hexadecimal and bit integer notation
]

;@@ TODO: replace `object!` headers with `struct!` datatype when it is mature enough?

palm-header: construct [
	name:
	attributes:
	version:
	created:
	modified:
	backuped:
	modification:
	appInfoID:
	sortInfoID:
	type:
	creator:
	uniqueIDSeed:
	nextRecordListID:
	records:
]

pdb-header: construct [
	compression:     ;; 1 == no compression, 2 = PalmDOC compression, 17480 = HUFF/CDIC compression
	unused:          ;; Always zero
	text-length:     ;; Uncompressed length of the entire text of the book
	records:         ;; Number of PDB records used for the text of the book.
	record-size:     ;; Maximum size of each record containing text, always 4096
	position:        ;; Current reading position, as an offset into the uncompressed text
]

mobi-header: construct [
;	length:          ;; The length of the MOBI header, including the previous 4 bytes
	type:            ;; The kind of Mobipocket file
	encoding:        ;; 1252 = CP1252 (WinLatin1); 65001 = UTF-8
	unique-id:       ;; Some kind of unique ID number (random?)
	file-version:    ;; Version of the Mobipocket format used in this file.
	orth-index:      ;;	Section number of orthographic meta index. 0xFFFFFFFF if index is not available.
	infl-index:      ;; Section number of inflection meta index. 0xFFFFFFFF if index is not available.
	names-index:     ;; 0xFFFFFFFF if index is not available.
	keys-index:      ;; 0xFFFFFFFF if index is not available.
	extra-index-0:   ;; Extra index 0	Section number of extra 0 meta index. 0xFFFFFFFF if index is not available.
	extra-index-1:   ;; Extra index 1	Section number of extra 1 meta index. 0xFFFFFFFF if index is not available.
	extra-index-2:   ;; Extra index 2	Section number of extra 2 meta index. 0xFFFFFFFF if index is not available.
	extra-index-3:   ;; Extra index 3	Section number of extra 3 meta index. 0xFFFFFFFF if index is not available.
	extra-index-4:   ;; Extra index 4	Section number of extra 4 meta index. 0xFFFFFFFF if index is not available.
	extra-index-5:   ;; Extra index 5	Section number of extra 5 meta index. 0xFFFFFFFF if index is not available.
	non-book-index:  ;; First Non-book index?	First record number (starting with 0) that's not the book's text
	fullname-offset: ;; Full Name Offset	Offset in record 0 (not from start of file) of the full name of the book
	fullname-length: ;; Full Name Length	Length in bytes of the full name of the book ()
	locale:          ;; Locale	Book locale code. Low byte is main language 09= English, next byte is dialect, 08 = British, 04 = US. Thus US English is 1033, UK English is 2057.
	input-language:  ;; Input Language	Input language for a dictionary
	output-language: ;; Output Language	Output language for a dictionary
	min-version:     ;; Min version	Minimum mobipocket version support needed to read this file.
	image-index:     ;; First Image index	First record number (starting with 0) that contains an image. Image records should be sequential.
	huffman-index:   ;; Huffman Record Offset	The record number of the first huffman compression record.
	huffman-count:   ;; Huffman Record Count	The number of huffman compression records.
	huffman-table:   ;; Huffman Table Offset	
	huffman-length:  ;; Huffman Table Length	
	exth-flags:      ;; EXTH flags	bitfield. if bit 6 (0x40) is set, then there's an EXTH record
	unknown-1:       ;;?	32 unknown bytes, if MOBI is long enough
	unknown-2:       ;; Unknown	Use 0xFFFFFFFF
	drm-index:       ;; DRM record number	Offset to DRM key info in DRMed files. 0xFFFFFFFF if no DRM
	drm-count:       ;; DRM Count	Number of entries in DRM info. 0xFFFFFFFF if no DRM
	drm-size:        ;; DRM Size	Number of bytes in DRM info.
	drm-flags:       ;; DRM Flags	Some flags concerning the DRM info.
	unknown-3:       ;; Unknown	Bytes to the end of the MOBI header, including the following if the header length >= 228 (244 from start of record). Use 0x0000000000000000.
	first-content:   ;; First content record number	Number of first text record. Normally 1.
	last-content:    ;; Last content record number	Number of last image record or number of last text record if it contains no images. Includes Image, DATP, HUFF, DRM.
	unknown-4:       ;; Unknown	Use 0x00000001.
	fcis-index:      ;; FCIS record number
	fcis-count:      ;; Unknown (FCIS record count?)	Use 0x00000001.
	flis-index:      ;; FLIS record number
	flis-count:      ;; Unknown (FLIS record count?)	Use 0x00000001.
	unknown-5:       ;; Unknown	Use 0x0000000000000000.
	srcs-index:      ;; SRCS record number
	comp-data:       ;; First Compilation data section count	Use 0x00000000.
	comp-data-count: ;; Number of Compilation data sections	Use 0xFFFFFFFF.
	unknown-7:       ;; Unknown	Use 0xFFFFFFFF.
	extra-flags:     ;; Extra Record Data Flags	A set of binary flags, some of which indicate extra data at the end of each text block. This only seems to be valid for Mobipocket format version 5 and 6 (and higher?), when the header length is 228 (0xE4) or 232 (0xE8).
	indx-index:      ;; INDX Record Offset	(If not 0xFFFFFFFF)The record number of the first INDX record created from an ncx file.
	unknown-8:       ;; Unknown	0xFFFFFFFF In new MOBI file, the MOBI header length is 256, skip this to EXTH header.
	unknown-9:       ;; Unknown	0xFFFFFFFF In new MOBI file, the MOBI header length is 256, skip this to EXTH header.
	unknown-10:      ;; Unknown	0xFFFFFFFF In new MOBI file, the MOBI header length is 256, skip this to EXTH header.
	unknown-11:      ;; Unknown	0xFFFFFFFF In new MOBI file, the MOBI header length is 256, skip this to EXTH header.
	unknown-12:      ;; Unknown	0xFFFFFFFF In new MOBI file, the MOBI header length is 256, skip this to EXTH header.
	unknown-13:      ;; Unknown	0 In new MOBI file, the MOBI header length is 256, skip this to EXTH header, MOBI Header length 256, and add 12 bytes from PalmDOC Header so this index is 268.
	boundary-offset: ;; BOUNDARY Record Offset
]

register-codec [
	name:  'mobi
	type:  'text
	title: "MobiPocket/Kindle Readers file"
	suffixes: [%.mobi %.azw]

	decode: function [
		{Extract content of the AR/LIB file}
		data  [binary! file! url!]
		;return: [object!]
	][
		unless binary? data [ data: read data ]
		result: object [
			palm: copy palm-header
			pdb:  copy pdb-header
			mobi: copy mobi-header
			exth: none
			name: none ;; full name as stored after EXTH records
			image: none
			srcs: none
			text: none ;; composed complete text
		]
		bin: binary data
		set result/palm binary/read bin [
			BYTES 32 ;; name
			UI16     ;; attr
			UI16     ;; version
			UI32     ;; date
			UI32     ;; modificationDate
			UI32     ;; lastBackupDate
			UI32     ;; modificationNumber
			UI32     ;; appInfoID
			UI32     ;; sortInfoID
			BYTES 4  ;; type
			BYTES 4  ;; creator
			UI32     ;; uniqueIDSeed
			UI32     ;; nextRecordListID
			UI16     ;; records
		]
		with result/palm [
			name:    to string! trim/tail name
			type:    to string! type
			creator: to string! creator
		]
		record-list: make block! 3 * result/palm/records
		loop result/palm/records [
			append record-list binary/read bin [UI32 UI8 UI24]
		]
		new-line/skip record-list true 3
		result/palm/records: record-list

		record0-offset: record-list/1
		set result/pdb binary/read bin [
			ATz :record0-offset
			UI16     ;; compression
			UI16     ;; unused
			UI32     ;; text-length
			UI16     ;; records
			UI16     ;; record-size
			UI32     ;; position
		]
		? result/pdb
		if result/pdb/compression <> 2 [
			do make error! ajoin ["[MOBI] Unsupported compression type: " result/pdb/compression]
		]

		if 0#4D4F4249 == binary/read bin 'UI32 [
			;; MOBI header....
			s: index? bin/buffer
			length: binary/read bin 'UI32

			set result/mobi binary/read bin compose [
				UI32     ;; type
				UI32     ;; encoding
				UI32     ;; unique-id
				UI32     ;; file-version
				UI32     ;; ort-index
				UI32     ;; inf-index
				UI32     ;; names-index
				UI32     ;; keys-index
				UI32     ;; extra-index-0
				UI32     ;; extra-index-1
				UI32     ;; extra-index-2
				UI32     ;; extra-index-3
				UI32     ;; extra-index-4
				UI32     ;; extra-index-5
				UI32     ;; non-book-index
				UI32     ;; fullname-offset
				UI32     ;; fullname-length
				UI32     ;; locale
				UI32     ;; input-language
				UI32     ;; output-language
				UI32     ;; min-version
				UI32     ;; image-index
				UI32     ;; huffman-index
				UI32     ;; huffman-count
				UI32     ;; huffman-table
				UI32     ;; huffman-length
				UI32     ;; exth-flags
				BYTES 32 ;; unknown-1
				UI32     ;; unknown-2
				UI32     ;; drm-offset
				UI32     ;; drm-count
				UI32     ;; drm-size
				UI32     ;; drm-flags
				UI64     ;; unknown-3
				UI16     ;; first-content
				UI16     ;; last-content
				UI32     ;; unknown-4
				UI32     ;; fcis-index
				UI32     ;; fcis-count
				UI32     ;; flis-index
				UI32     ;; flis-count
				UI64     ;; unknown-5
				UI32     ;; unknown-6
				UI32     ;; comp-data
				UI32     ;; comp-data-count
				UI32     ;; unknown-7
				UI32     ;; extra-flags
				UI32     ;; indx-index
				(either/only length > 232 [
					UI32 ;; unknown-8
					UI32 ;; unknown-9
					UI32 ;; unknown-10
					UI32 ;; unknown-11
					UI32 ;; unknown-12
					UI32 ;; unknown-13
				][])
				(either/only length > 252 [
					UI32 ;; boundary-offset
				][])
			]
			? result/mobi
			;print ["Mobi len:" (index? bin/buffer) - s]
		]
		bin/buffer: atz head bin/buffer (record0-offset + 16 + length)
		if 0#45585448 == binary/read bin 'UI32 [
			;; EXTH header....
			binary/read bin [
				length: UI32
				count:  UI32 ;; The number of records in the EXTH header.
			]
			;; The rest of the EXTH header consists of repeated EXTH records to the end of the EXTH length.
			result/exth: exth: make block! 3 * count
			loop count [
				binary/read bin [
					type: UI32
					len:  UI32
				]
				data: binary/read bin len - 8
				spec: any [select EXTH_RECORD_TYPE type [binary! Unknown]]
				data: reduce [type  spec/2  to get spec/1 data]
				printf [-4 SP 22 ": "] data
				append exth new-line data true
			]
			print ""
		]

		try [
			bin/buffer: atz head bin/buffer (record0-offset + result/mobi/fullname-offset)
			result/name: to string! trim/tail copy/part bin/buffer result/mobi/fullname-length
		]

		try [if result/mobi/srcs-index [
			record-list: skip head record-list 3 * result/mobi/srcs-index
			ofs: record-list/1
			len: record-list/4 - ofs
			binary/read bin [ATz :ofs srcs: UI32]
			if srcs = 0#53524353 [
				binary/read bin [UI32 UI32 UI32]
				result/srcs: srcs: binary/read bin (len - 16)
				try [result/srcs: system/codecs/zip/decode srcs]
			]
			
		]]

		try/with [if result/mobi/image-index [
			record-list: skip head record-list 3 * result/mobi/image-index
			ofs: record-list/1
			len: record-list/4 - ofs
			binary/read bin [ATz :ofs image: BYTES :len]
			result/image: switch/default binary/read image 'UI16BE [
				0#ffd8 [sys/decode 'jpeg image]
				0#8950 [sys/decode 'png  image]
				0#4749 [sys/decode 'gif  image]
			][ image ]
		]] :print

		;; Decompress the text...
		result/text: make binary! result/pdb/text-length
		record-list: skip head record-list 3 ; * result/mobi/first-content
		loop result/pdb/records [
			ofs: record-list/1
			len: record-list/4 - ofs
			append/part result/text decompress-palmdoc atz head bin/buffer :ofs :len 4096
			record-list: skip record-list 3
		]
		;while [not tail? record-list: skip record-list 3] [		
		;	prin [record-list/3 >> 1 record-list/1 TAB]
		;	probe to-string copy/part atz head bin/buffer record-list/1 4
		;]

		result
	]
]

decompress-palmdoc: function[bin [binary!] limit [integer!]][
	out: clear #{}
	end: limit + index? bin
	while [end > index? bin][
		byte: bin/1
		++ bin
		case [
			byte == 0 [append out 0]
			byte <= 8 [append/part out bin byte bin: skip bin byte]
			byte <= 2#01111111 [append out byte]
			byte <= 2#10111111 [
				; 1st and 2nd bits are 10, meaning this is a length-distance pair
				; read next byte and combine it with current byte
				bytes: (byte << 8) | bin/1
				++ bin
				;; the 3rd to 13th bits encode distance
				distance: (bytes & 2#0011111111111111) >> 3
				;; the last 3 bits, plus 3, is the length to copy
				length: (bytes & 2#111) + 3

				;; Getting text from the offset is a little tricky, because
				;; in theory you can be referring to characters you haven't
				;; actually decompressed yet.
				wpos: length? out
				rpos: wpos - distance
				either wpos > (rpos + length) [
					;; All chars are already available, so just copy all at once
					append/part out atz out :rpos :length
				][
					;; Referring to characters not decompressed yet.
					;; Therefore check the reference one character at a time!
					loop length [
						++ rpos
						append out out/:rpos
					]
				]
			]
			'else [
				;; compressed from space plus char
				append append out SP (byte xor 2#10000000)
			]
		]
		if 4096 <= length? out [break]
	]
	out
]

EXTH_RECORD_TYPE: make map! [
	1	[binary!  Drm-server-id]
	2	[binary!  Drm-commerce-id]
	3	[binary!  Drm-ebookbase-book-id]
	100	[string!  Author]
	101	[string!  Publisher]
	102	[string!  Imprint]
	103	[string!  Description]
	104	[string!  Isbn]
	105	[string!  Subject]
	106	[string!  Publishingdate]
	107	[string!  Review]
	108	[string!  Contributor]
	109	[string!  Rights]
	110	[string!  Subjectcode]
	111	[string!  Type]
	112	[string!  Source]
	113	[string!  Asin]                  ;; Kindle Paperwhite labels books with "Personal" if they don't have this record.	
	114	[binary!  Versionnumber]
	115	[integer! Sample]                ;; 0x0001 if the book content is only a sample of the full book	
	116	[integer! Startreading]          ;; Position (4-byte offset) in file at which to open when first opened	
	117	[string!  Adult]                 ;; Mobipocket Creator adds this if Adult only is checked on its GUI; contents: "yes"
	118	[string!  Retail-price]          ;; As text, e.g. "4.99"
	119	[string!  Retail-price-currency] ;; As text, e.g. "USD"
	121	[integer! KF8-boundary-offset]
	122	[string!  Fixed-layout]
	123	[string!  Book-type]
	124	[string!  Orientation-lock]
	125	[integer! Count-of-resources]
	126	[string!  Original-resolution]
	127	[string!  Zero-gutter]
	128	[string!  Zero-margin]
	129	[string!  Metadata-Resource-URI]
	131	[integer! Unidentified-count]
	200	[string!  Dictionary-short-name]
	201	[integer! Coveroffset]          ;; Add to first image field in Mobi Header to find PDB record containing the cover image
	202	[integer! Thumboffset]          ;; Add to first image field in Mobi Header to find PDB record containing the thumbnail cover image	
	203	[integer! Hasfakecover]
	204	[integer! Creator-Software]     ;; Known Values: 1=mobigen, 2=Mobipocket Creator, 200=kindlegen (Windows), 201=kindlegen (Linux), 202=kindlegen (Mac).
	205	[integer! Creator-Major-Version]
	206	[integer! Creator-Minor-Version]
	207	[integer! Creator-Build-Number]
	208	[binary!  Watermark]
	209	[binary!  Tamper-proof-keys]    ;; Used by the Kindle (and Android app) for generating book-specific PIDs.	
	300	[binary!  Fontsignature]
	401	[integer! Clippinglimit]        ;; Integer percentage of the text allowed to be clipped. Usually 10.	
	402	[integer! Publisherlimit]
	404	[integer! TTSflag]              ;; 1 - Text to Speech disabled; 0 - Text to Speech enabled	
	405	[integer! Rental]               ;; (Rent/Borrow flag?) 1 in this field seems to indicate a rental book	
	406	[binary!  Expiration-Date]       ;; (Rent/Borrow) If this field is removed from a rental, the book says it expired in 1969	
;	407	[binary!  Unknown]
;	450	[binary!  Unknown]
;	451	[binary!  Unknown]
;	452	[binary!  Unknown]
;	453	[binary!  Unknown]
	501	[string!  Cdetype]              ;; PDOC - Personal Doc; EBOK - ebook; EBSP - ebook sample;	
	502	[string!  Lastupdatetime]
	503	[string!  Updatedtitle]
	504	[string!  Asin]                 ;; I found a copy of ASIN in this record.	
	524	[string!  Language]
	525	[string!  Writingmode]          ;; I found horizontal-lr in this record.
	527 [string!  Page-progression-direction]
	528 [string!  Override-kindle-fonts]
	529 [string!  Kindlegen-Source-Target]
	534 [string!  Input-Source-Type]
	535	[string!  Kindlegen-Build-Number] ;; I found 1019-d6e4792 in this record, which is a build number of Kindlegen 2.7	
	536	[string!  Container-info]
	538 [string!  Container-resolution]
	539 [string!  Container-mimetype]
;	542	[binary!  Unknown]              ;; Some Unix timestamp.
	543 [binary!  Container-id]
	547	[string!  InMemory]
]