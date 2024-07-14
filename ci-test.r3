Rebol [title: "MOBI codec CI test"]

system/options/quiet: false
system/options/log/rebol: 4

import %mobi.reb

system/options/log/mobi: 4

foreach [file url] [
	%RUR.v1.mobi https://www.gutenberg.org/ebooks/13083.kindle.images
	%RUR.v2.mobi https://www.gutenberg.org/ebooks/13083.kf8.images
][
	print-horizontal-line
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

	print-horizontal-line
	print as-yellow "Decode the book using `decode` function:"
	try/with [
		;; Decode raw binary data already in memory...
		data: decode 'mobi file
	][
		print as-purple "*** Failed to decode a book!"
		print system/state/last-error
		quit/return -2
	]

	print as-green "MOBI data succesfully decoded!"
	? data ;print to-string data/text
	
	print-horizontal-line
	print as-yellow "Decode the book using a scheme:"
	try/with [
		book: open [scheme: 'mobi path: file]
		;; all metadata should be decoded when the port is opened...
		? book
		probe query book
		;; when text is needed, use READ on the port...
		text: read/string book
		? text ;print text
		close book
	][
		print as-purple "*** Failed to decode a book!"
		print system/state/last-error
		quit/return -3
	]
]