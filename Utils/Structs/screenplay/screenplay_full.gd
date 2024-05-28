extends Resource
class_name ScreenplayFull

var card_count : int
var cards : Array[ScreenplayCard] = []
var map_name_cards : Array[int] = []
var map_display_cards : Array[int] = []

func decode_from_stream(data: StreamPeerBuffer):
	card_count = data.get_16()


	for card in card_count:
		var s := ScreenplayCard.new()
		s.decode_from_stream(data)
		cards.append(s)

	print(cards[100])

	locate_map_cards()

func locate_map_cards():
	for entry in cards[0].entries:
		map_name_cards.append(entry.info[0][1])
		if entry.info[0].size() > 2:
			map_display_cards.append(entry.info[0][2])
			
