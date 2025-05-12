extends Resource
class_name ScreenplayCard
enum EntryTypes {DATA, FLAG, ITEM, POSE, MANTRA, MISC}
@export var size : int
@export var entries : Array = []

enum MapIcons {BLANK, BACKSIDE, GRAIL, CROSS, FAIRY, BROWNDOOR, BLUEDOOR, PHILOSOPHER, UP, DOWN, LEFT, RIGHT, BONE}

static func icon_vec_to_num(vec : Vector3i):
	return 1000 * vec.x + 10 * vec.y + vec.z
	
static func icon_num_to_vec(num : int):
	return Vector3i(floori(num / 1000), floori((num % 1000) / 10), num % 10)

static var screenplay_font : String = \
	"!\"&'(),-./0123456789:?ABCDEFGHIJKLMNOPQRSTUVWXYZ\
　]^_abcdefghijklmnopqrstuvwxyz…♪、。々「」ぁあぃいぅうぇえぉおか\
がきぎくぐけげこごさざしじすずせぜそぞただちぢっつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほ\
ぼぽまみむめもゃやゅゆょよらりるれろわをんァアィイゥウェエォオカガキギクグケゲコゴサザシジスズセ\
ゼソゾタダチヂッツヅテデトドナニヌネノハバパヒビピフブプヘベペホボポマミムメモャヤュユョヨラリル\
レロワヲンヴ・ー一三上下不与世丘両中丸主乗乙乱乳予争事二人今介仕他付代以仮仲件会伝位低住体何作使\
供侵係保信俺倍倒値偉側偶備傷像僧元兄先光兜入全公具典内再冒冥出刀分切列初別利刻則前剣創力加助効勇\
勉動化匹十半協博印危去参双反取受叡口古召可台史右司合同名向否周呪味呼命品唯唱問喜営器噴四回囲図国\
土在地坂型域基堂報場塊塔墓増壁壇壊士声売壷変外多夜夢大天太央失奇契奥女好妊妖妻始姿娘婦子字存孤学\
宇守官宙定宝実客室宮家密寝対封専導小少尾屋屏属山岩崖崩嵐左巨己布帯帰常年幸幻幾広床底店度座庫廊廟\
弁引弟弱張強弾当形影役彼待後心必忍忘応念怒思急性怨恐息恵悔悟悪悲情惑想意愚愛感慈態憶我戦戻所扉手\
扱投抜押拝拡拳拾持指振探撃撮操支攻放敗教散数敵敷文料斧断新方旅族日早昇明昔星映時晩普晶智暗曲書最\
月有服望未末本杉村杖束来杯板析果架柱査格械棺検椿楼楽槍様槽模樹橋機欠次欲歓止正武歩歯歳歴死殊残段\
殺殿母毒毛気水氷永求汝池決治法波泥注洞洪流海消涙涯深済減湖満源溶滅滝火灯灼炎無然熱爆爪父版牛物特\
犬状狂独獄獅獣玄玉王珠現球理瓶生産用男画界略番発登白百的盤目直盾看真眼着知石研破碑示礼社祈祖神祠\
祭禁福私秘秤移種穴究空突窟立竜章竪端笛符第筒答箱範精系約納純紫細紹終経結続緑練罠罪罰義羽習翻翼老\
考者耐聖聞肉肩胸能脱腕自至船色若苦英荷華落葉蔵薇薔薬蛇血行術衛表裁装裏補製複要見覚親解言記訳証試\
話詳認誕誘語誠説読誰調論謁謎謝識議護谷貝財貧貯買貸資賢贄贖赤走起超足跡路踊蹴身車軽輝辞込辿近返迷\
追送逃通速造連進遊過道達違遠適選遺還郎部配重野量金針鉄銀銃銅録鍵鎖鏡長門閉開間関闇闘防限険陽階隠\
雄雑難雨霊青静面革靴音順領頭題顔願類風飛食館馬駄験骨高魂魔魚鳥鳴黄黒泉居転清成仏拠維視宿浮熟飾冷\
得集安割栄偽屍伸巻緒捨固届叩越激彫蘇狭浅Ⅱ［］：！？～／０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪ\
ＫＬＭＮＯＰＲＳＴＵＶＷＸＹａｂｄｅｇｈｉｌｍｏｐｒｓｔｕｘ辺薄島異温復称狙豊穣虫絶ＱＺｃｆｊｋ\
ｎｑｖｗｙｚ＋－旧了設更橫幅似確置整＞％香ü描園為渡象相聴比較掘酷艇原民雷絵南米平木秋田県湯環砂\
漠角運湿円背負構授輪圏隙草植快埋寺院妙該式判（）警告収首腰芸酒美組各演点勝観編丈夫姫救’，．霧節\
幽技師柄期瞬電購任販Á;û+→↓←↑⓪①②③④⑤⑥⑦⑧⑨<”挑朝痛魅鍛戒飲憂照磨射互降沈醜触煮疲\
素競際易堅豪屈潔削除替Ü♡*$街極"

static var reverse_font = {}

func add_entry_after(entry_data : ScreenplayEntry, entry_pos : int = entries.size()):
	if entry_pos >= entries.size(): #Adding at the end, so the previous entry needs a BREAK but this one does not
		entries[entries.size() - 1].info.append(["BREAK"])
	else:
		entry_data.info.append(["BREAK"])
	entries.insert(entry_pos+1, entry_data)

static func from_line_array(full_line_array):
	var card = ScreenplayCard.new()
	for l in full_line_array:
		card.entries.append(ScreenplayEntry.from_string(l))
	card.size = card.calc_size()
	return card

# Mutates this card into the passed card. Useful for saving.
func become(new_card):
	entries = new_card.entries
	size = new_card.size

# A card is made of of multiple entries, which are essentially different "lines" of info
class ScreenplayEntry:
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

func calc_size():
	var calced_size = 0
	for e in entries:
		calced_size += e.calc_size()
	#calced_size += entries.size() - 1 #The final entry does not have a break
	return calced_size * 2 # Each read in the file is actually two bytes

func _to_string():
	var result : String = "Size: %s\n" % size
	result += "Calced size: %s \n" % calc_size()
	result += "Entry count: %s \n" % entries.size()
	for e in entries:
		result += "%s \n" % e
	return result

func decode_from_stream(data :StreamPeerBuffer):
	size = data.get_16()
	var has_break_already = false
	var card_data = data_to_array(data, size)
	while not card_data.is_empty():
		var e = ScreenplayEntry.new()
		e.read_entry(card_data)
		entries.append(e)
	#var final_entry = entries[entries.size()-1]
	#if final_entry.type == EntryTypes.DATA:
		#print(final_entry)
		#if final_entry.info[0][final_entry.info[0].size() - 1] == 0x000A:
			#size += 2


func write(buf : StreamPeerBuffer):
	buf.put_16(size)
	for e in entries:
		e.write(buf)

	#var internal_size = calc_size()
	#if internal_size > size:
		#print("internal size too big! %s" % (internal_size - size))
		#print(size)
	#elif internal_size < size:
		#print("internal size too small! %s" % (size - internal_size))

#func read_data_entry(data: StreamPeerBuffer):
	#var entry_type : EntryTypes = EntryTypes.DATA
	#var data_values : Array[int] = []
	#var data_count : int = data.get_16()
	#for d in data_count:
		#data_values.append(data.get_16())
	#print(data_values)
	#return {"type": entry_type, "data": data_values}

func data_to_array(data: StreamPeerBuffer, data_size : int):
	var result : Array[int] = []
	if data_size % 2 != 0 :
		printerr("Screenplay card data is an odd size!")
	for i in data_size/2:
		result.append(data.get_16())
	return result

class MapVisualCard:
	extends ScreenplayCard
