extends Resource
# A card is made of of multiple entries, which are essentially different "lines" of info
class_name ScreenplayEntry
enum EntryTypes {DATA, FLAG, ITEM, POSE, MANTRA, MISC}

@export var type : EntryTypes
@export var info : Array  = []
func _init(t : EntryTypes = EntryTypes.MISC, i : Array = []):
	type = t
	info = i
func _to_string():
	return var_to_str([type, info])
	#return "Type %s info %s" % [type, info]

static func from_string(s : String):
	var parsed_string = str_to_var(s)
	return ScreenplayEntry.new(parsed_string[0], parsed_string[1])

func calc_size():
	var calced_size = 0
	for elem in info:
		if elem is Array:
			calced_size += elem.size()
		elif elem is String:
			calced_size += elem.length()
		else:
			printerr("Weird value in screenplay entry info")
	if type == EntryTypes.DATA:
		calced_size += 1
	return calced_size

func read_entry(card_data: Array): #Reads until finding the 0x00A0, which is the divider for entries
	var s = ""
	while true:
		var b = card_data.pop_front()
		if b == null:
			if not s.is_empty():
				info.append(s)
				s = ""
			return

		# Things that are not strings, special commands. Reset the stored string
		elif b == 0x000A:
			if not s.is_empty():
				info.append(s)
				s = ""
			info.append(["BREAK"])
			return
		elif b >= 0x0040 and b < 0x0050:
			if not s.is_empty():
				info.append(s)
				s = ""
			if b == 0x0040:
				info.append(["Flag", card_data.pop_front(), card_data.pop_front()])
			elif b == 0x0042:
				info.append(["Item", card_data.pop_front()])
			elif b == 0x0044:
				info.append(["Clear"])
			elif b == 0x0045:
				info.append(["Newline"])
			elif b == 0x0046:
				info.append(["Pose", card_data.pop_front()])
			elif b == 0x0047:
				info.append(["Mantra", card_data.pop_front()])
			elif b == 0x004A:
				info.append(["Colour", card_data.pop_front(),card_data.pop_front(),card_data.pop_front()])
			elif b == 0x004E:
				type = EntryTypes.DATA
				var entry_size = card_data.pop_front()
				var data_details = ["Data"]
				for j in entry_size:
					data_details.append(card_data.pop_front())
				info.append(data_details)
			elif b == 0x004F:
				info.append(["Anime", card_data.pop_front()])

		# Things that are part of strings
		elif b == 0x000C:
			s += "✧"
		elif b == 0x0020:
			s += " "
		elif b == 0x05c1:
			s += ("★")
		elif b == 0x05c2:
			s += ("☆")
		elif b == 0x05c3:
			s += ("✦")
		elif b >= 0x0100 and b <= 0x1061:
			s += ScreenplayCard.screenplay_font[b-0x0100]
		else:
			printerr("Found an unrecognized entry type %s" % b)

func write(buf : StreamPeerBuffer):
	if info.size() == 0:
		buf.put_16(0x000A)
		return
	for part in info:
		if part is String:
			for letter in part:
				if letter == "✧":
					buf.put_16(0x000C)
				elif letter == " ":
					buf.put_16(0x0020)
				elif letter == "★":
					buf.put_16(0x05c1)
				elif letter == "☆":
					buf.put_16(0x05c2)
				elif letter == "✦":
					buf.put_16(0x05c3)
				else:
					buf.put_16(ScreenplayCard.reverse_font[letter] + 0x0100)
		elif part is Array:
			if part[0] == "BREAK":
				buf.put_16(0x000A)
			if part[0] == "Flag":
				buf.put_16(0x0040)
				buf.put_16(part[1])
				buf.put_16(part[2])
			elif part[0] == "Item":
				buf.put_16(0x0042)
				buf.put_16(part[1])
			elif part[0] == "Clear":
				buf.put_16(0x0044)
			elif part[0] == "Newline":
				buf.put_16(0x0045)
			elif part[0] == "Pose":
				buf.put_16(0x0046)
				buf.put_16(part[1])
			elif part[0] == "Mantra":
				buf.put_16(0x0047)
				buf.put_16(part[1])
			elif part[0] == "Colour":
				buf.put_16(0x004a)
				buf.put_16(part[1])
				buf.put_16(part[2])
				buf.put_16(part[3])
			elif part[0] == "Anime":
				buf.put_16(0x004F)
				buf.put_16(part[1])
			elif part[0] == "Data":
				buf.put_16(0x004E)
				var a = part.slice(1)
				buf.put_16(a.size())
				for d in a:
					buf.put_16(d)
		else:
			printerr("Writing an invalid screenplay entry")
