Rebol [title: "MOBI codec CI test"]

system/options/quiet: false
system/options/log/rebol: 4

import %mobi.reb

foreach url [
	https://www.gutenberg.org/ebooks/13083.kindle.images
	https://www.gutenberg.org/ebooks/13083.kf8.images
][
	print-horizontal-line
	print [as-green "Downloading book from:" as-yellow url]

	try/with [
		;; Download a book for a test...
		book: read url
	][
		print as-purple "*** Failed to download a book!"
		quit/return -1
	]

	try/with [
		;; Decode raw binary data already in memory...
		data: decode 'mobi book
	][
		print as-purple "*** Failed to decode a book!"
		print system/state/last-error
		quit/return -2
	]

	print as-green "MOBI data succesfully decoded!"
	? data
	print to string! data/text
]