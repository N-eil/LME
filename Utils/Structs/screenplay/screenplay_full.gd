extends Resource
class_name ScreenplayFull

var card_count : int
var cards : Array[ScreenplayCard] = []
var map_name_cards : Array[int] = []
var map_display_cards : Array[int] = []

func decode_from_stream(data: StreamPeerBuffer):
	for c in ScreenplayCard.screenplay_font.length(): #Setup the reverse font only a single time, used for writing.
		ScreenplayCard.reverse_font[ScreenplayCard.screenplay_font[c]] = c

	card_count = data.get_16()
	for card in card_count:
		var s := ScreenplayCard.new()
		s.decode_from_stream(data)
		cards.append(s)	

	locate_map_cards()

func write(buf : StreamPeerBuffer):
	buf.put_16(card_count)
	
	for card in cards:
		card.size = card.calc_size()
		card.write(buf)
		#if card.size != card.calc_size():
			#printerr("Sizes did not match and could not write card %s" % card)

func locate_map_cards():
	for entry in cards[0].entries:
		map_name_cards.append(entry.info[0][1])
		if entry.info[0].size() > 2:
			map_display_cards.append(entry.info[0][2])
			
