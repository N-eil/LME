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
	#The very first screenplay entry is hardcoded to have the locations of all map-related entries.
	# e.g. an entry is [0, [["Data", 25, 512], ["BREAK"]]]. That means the names for that field are in card 25 and the visuals are in card 512
	for entry in cards[0].entries:
		# Use that hardcoded list to find where all the map name entries are in the file and store them
		map_name_cards.append(entry.info[0][1])

		# And same with the map visual display, if it exists.
		if entry.info[0].size() > 2:
			map_display_cards.append(entry.info[0][2])

# Removes all room and name data about a field, so it is blank to add new data
func clear_field_from_map(index : int):
	#Have to look into the map related arrays to find which screenplay to blank
	cards[map_display_cards[index]] = ScreenplayCard.new()
	cards[map_name_cards[index]] = ScreenplayCard.new()

func add_room_to_field(room_name : String, room_position : Vector2i):
	pass
