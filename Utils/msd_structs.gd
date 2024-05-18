class_name MsdStructs


const msd_graphics_map = ["map00_1.png", "map01_1.png",
	"map02_1.png", "map03_1.png", "map04_1.png", "map05_1.png", "map06_1.png", "map07_1.png", "map08_1.png", "map09_1.png", "map10_1.png", "map11_1.png", "map12_1.png", "map13_1.png", "map14_1.png", "map15_1.png",
	"map16_1.png", "map17_1.png", "", "", "", "", "", "", "", "", "", "", "", "map18_1.png", "map19_1.png", "map19_1.png"    
	]

class MSDMap:
	extends Resource
	var animated_tiles : Array[AnimatedTile]
	var animated_tiles_map : Dictionary
	var animated_tiles_end : int
	var graphics_id : int
	var unk : int
	var room_count : int
	var rooms : Array [MSDRoom]
	
	var msd_id : int
	var graphics_filename : String
	
	func read_sizes(data: StreamPeerBuffer, id):
		var animated_tile_check
		while(true):
			animated_tile_check = AnimatedTile.new()
			animated_tile_check.read(data)
			if (animated_tile_check.frame_count == 0):
				animated_tiles_end = 0
				break
				
		graphics_id = data.get_8()
		graphics_filename = msd_graphics_map[graphics_id - 2]
		
		unk = data.get_8()
		room_count = data.get_8()
		
		for i in range(room_count):
			var r = MSDRoom.new()
			r.read_sizes(data)
			rooms.append(r)
		
	func read(data : StreamPeerBuffer, id):
		msd_id = id
		var animated_tile_check
		while(true):
			animated_tile_check = AnimatedTile.new()
			animated_tile_check.read(data)
			if (animated_tile_check.frame_count == 0):
				animated_tiles_end = 0
				break
			animated_tiles_map[animated_tile_check.frames[0].coords] = animated_tile_check
			animated_tiles.append(animated_tile_check)
		graphics_id = data.get_8()
		graphics_filename = msd_graphics_map[graphics_id - 2]
		
		unk = data.get_8()
		room_count = data.get_8()
		
		for i in range(room_count):
			var r = MSDRoom.new()
			r.read(data)
			rooms.append(r)

	func write(buf : StreamPeerBuffer):
		for a in animated_tiles:
			a.write(buf)
		buf.put_16(0)
		buf.put_8(graphics_id)
		buf.put_8(unk)
		buf.put_8(room_count)
		for r in rooms:
			r.write(buf)      

class AnimatedTile:
	var animate_in_boss : bool
	var frame_count : int
	var frames : Array

	func read(data : StreamPeerBuffer):
		var tileInfo = data.get_16()
		animate_in_boss = tileInfo & 0x8000
		frame_count = tileInfo & 0x7FFF
		for i in range(frame_count):
			var f = AnimatedTileID.new()
			f.read(data)
			frames.append(f)

	func write(buf : StreamPeerBuffer):
		buf.put_16(frame_count + (0x8000 if animate_in_boss else 0))
		for f in frames:
			f.write(buf)

class AnimatedTileID:
	var frames_wait : int
	var coords : int

	func read(data : StreamPeerBuffer):
		var tile_info = data.get_16()
		coords = (tile_info & 0x07FF)
		frames_wait = ((tile_info & 0xF800) >> 11)

	
	func write(buf : StreamPeerBuffer):
		buf.put_16(coords)

class MSDRoom:
	var use_boss_graphics : bool
	var layer_count : int
	var prime_layer_index : int
	var hit_mask_width : int
	var hit_mask_height : int
	var hit_mask
	var layers : Array[Layer]
	
	var screen_count : int
	var horizontal_screen_count : int
	var vertical_screen_count : int
	
	static func get_top_left_2d(screen_id, h_screen_count, horz_offsize = 0, vert_offsize = 0):
		if (h_screen_count == 0):
			return Vector2(0,0)
		var screens_above = floor(screen_id/h_screen_count)
		var screens_left = screen_id % h_screen_count
		return Vector2(screens_left * (32 + horz_offsize), (screens_above * (24 + vert_offsize)))

	static func unflatten_tile_array(tiles_1d, width, height):
		var tiles_2d = []
		var i = 0
		var current_row = []
		while i < width * height:
			if i != 0 and i % width == 0:
				tiles_2d.append(current_row)
				current_row = []
			current_row.append(tiles_1d[i])
			i += 1
		tiles_2d.append(current_row)
		return tiles_2d

	static func flatten_tile_array(tiles_2d):
		var tiles_1d = []
		for r in tiles_2d:
			for t in r:
				tiles_1d.append(t)
		return tiles_1d

	func get_hitmask_top_left(screen_id):
		return MSDRoom.get_top_left_2d(screen_id, horizontal_screen_count, 32, 24)
	
	func add_screen(source_screen_id, is_horizontal = true):  #TODO: currently only adds screens directly to the right
		# TODO: currently only adds one layer
				
		# Expand hitmask (horizontal)
		for r in hit_mask: 
			for i in range(32 * 2):
				r.append(0)
   
		var prime_layer = layers[prime_layer_index]
		# Expand prime layer (horizontal)
		if (is_horizontal):
			horizontal_screen_count += 1
			prime_layer.horizontal_screen_count += 1 
			hit_mask_width += 32 * 2
		else:
			vertical_screen_count += 1
			prime_layer.vertical_screen_count += 1
			hit_mask_height += 24 * 2
		screen_count += 1
		prime_layer.screen_count += 1
		
		#TODO: Expand all sublayers
		for l in layers:
#            var grow_amount =  32 + ((l.layer_width / l.horizontal_screen_count) - 32) * 2
			var grow_amount = 32 + l.horz_offsize
			l.layer_width += grow_amount
			l.tile_count = l.layer_width * l.layer_height
			
			for s in l.sublayers:
#        var growing_sublayer = prime_layer.sublayers[0]
				for r in s.tiles: 
					for i in range(grow_amount):
						r.append(Tile.new())        
		
		# Expand all layers? 
		if (screen_count > 0):
			for i in range(layer_count):
				layers[i].vertical_screen_count = vertical_screen_count
				layers[i].horizontal_screen_count = horizontal_screen_count 
				layers[i].screen_count = screen_count       
 
	func read_sizes(data : StreamPeerBuffer):
		use_boss_graphics = (data.get_8() == 1)
		layer_count = data.get_8()
		prime_layer_index = data.get_8()
		hit_mask_width = data.get_16()
		hit_mask_height = data.get_16()       

		data.get_data(hit_mask_height * hit_mask_width)
		
		for i in range(layer_count):
			var l = Layer.new()
			l.read_sizes(data)
			if i == prime_layer_index:
				screen_count = l.screen_count
#        if (layer_count > prime_layer_index):
#            screen_count = layers[prime_layer_index].screen_count
		
	func read(data : StreamPeerBuffer):
		use_boss_graphics = (data.get_8() == 1)
		layer_count = data.get_8()
		prime_layer_index = data.get_8()
		hit_mask_width = data.get_16()
		hit_mask_height = data.get_16()       

		var flat_hit_mask = data.get_data(hit_mask_height * hit_mask_width)[1]
		hit_mask = MSDRoom.unflatten_tile_array(flat_hit_mask, hit_mask_width, hit_mask_height)
		for i in range(layer_count):
			var l = Layer.new()
			l.read(data)
			layers.append(l)
			
		if (layer_count > prime_layer_index):
			layers[prime_layer_index].is_prime_layer = true
			screen_count = layers[prime_layer_index].screen_count
			vertical_screen_count = layers[prime_layer_index].vertical_screen_count
			horizontal_screen_count = layers[prime_layer_index].horizontal_screen_count
		
		if (screen_count > 0):
			for i in range(layer_count):
				layers[i].vertical_screen_count = vertical_screen_count
				layers[i].horizontal_screen_count = horizontal_screen_count
				layers[i].horz_offsize = layers[i].layer_width - (horizontal_screen_count * 32)
				layers[i].vert_offsize = layers[i].layer_height - (vertical_screen_count * 24)
		
	func write(buf : StreamPeerBuffer):
		buf.put_8(1 if use_boss_graphics else 0)
		buf.put_8(layer_count)
		buf.put_8(prime_layer_index)
		
		# TODO REMOVE
		# This code increases the size of only the prime layer by 32
		# It's also bugged somehow
#		for l in layers:
#			if (l.is_prime_layer and l.layer_width >= 32):
#				l.layer_width += 32
#				l.tile_count = l.layer_width * l.layer_height
#				for s in l.sublayers:
#					s.tile_count = l.tile_count
#					for r in s.tiles:	
#						r += (r.slice(len(r) - 32, len(r) - 1))
#		if hit_mask_width >= 64:
#			hit_mask_width += 64
#			for r in hit_mask:	
#				r += (r.slice(len(r) - 64, len(r) - 1))
		# --------- To here
		
		buf.put_16(hit_mask_width)
		buf.put_16(hit_mask_height)
		var flat_hit_mask = MSDRoom.flatten_tile_array(hit_mask)
		buf.put_data(flat_hit_mask)
		
		for l in layers:
			l.write(buf)

# Default values make a layer that is exactly one single screen
class Layer:
	var layer_width : int = 32
	var layer_height : int = 24 
	var sublayer_count : int = 0
	var sublayers : Array[Sublayer]

	var tile_count : int = 768
	var screen_count : int = 1
	
	var horizontal_screen_count : int = 1
	var vertical_screen_count : int = 1
	var is_prime_layer : bool = false

	var horz_offsize = 0
	var vert_offsize = 0

	func add_sublayer(s):
		sublayer_count += 1
		sublayers.append(s)

	func get_top_left_1d(screen_id):
#        if (horizontal_screen_count == 0):
#            return 0
#        var screens_above = floor(screen_id/horizontal_screen_count) * horizontal_screen_count
#        var screens_left = screen_id % horizontal_screen_count
#        var horz_offsize = layer_width - (horizontal_screen_count * 32)
#        var vert_offsize = layer_height - (vertical_screen_count * 24)
#        return (0 + (screens_left * (32 + horz_offsize)) + (screens_above * layer_width * (24 + vert_offsize)))
		var top_left = get_top_left_2d(screen_id)
		return (0 + top_left.x + top_left.y * layer_width)
		
	func get_top_left_2d(screen_id):
		return MSDRoom.get_top_left_2d(screen_id, horizontal_screen_count, horz_offsize, vert_offsize)#Vector2(screens_left * (32 + horz_offsize), (screens_above * (24 + vert_offsize)))
	
	func read_sizes(data : StreamPeerBuffer):
		layer_width = data.get_16()
		layer_height = data.get_16()
		tile_count = layer_height * layer_width
		horizontal_screen_count = (layer_width / 32)
		vertical_screen_count = (layer_height / 24)
		screen_count = horizontal_screen_count * vertical_screen_count
		
		sublayer_count = data.get_8()
		for i in range(sublayer_count):
			data.get_data(2 * tile_count)
	
	func read(data : StreamPeerBuffer):
		layer_width = data.get_16()
		layer_height = data.get_16()
		tile_count = layer_height * layer_width
		horizontal_screen_count = (layer_width / 32)
		vertical_screen_count = (layer_height / 24)
		screen_count = horizontal_screen_count * vertical_screen_count
		
		sublayer_count = data.get_8()
		for i in range(sublayer_count):
			var s = Sublayer.new()
			s.index = i
			s.read(data, self)
			sublayers.append(s)
		is_prime_layer = false           

	func write(buf : StreamPeerBuffer):
		buf.put_16(layer_width)
		buf.put_16(layer_height)
		buf.put_8(sublayer_count)
		for s in sublayers:
			s.write(buf)
   
class Sublayer:
	var tiles : Array
	var tile_count : int
	var index : int

	func read(data : StreamPeerBuffer, l : Layer):
		tile_count = l.tile_count
		var tiles_1d : Array
		for i in range(tile_count):
			var t = Tile.new()
			t.read(data)
			tiles_1d.append(t)
		tiles = MSDRoom.unflatten_tile_array(tiles_1d, l.layer_width, l.layer_height)
		
	func write(buf : StreamPeerBuffer):
		for t in MSDRoom.flatten_tile_array(tiles):
			t.write(buf)        

	static func create_empty(width, height):
		var tiles_1d : Array[Tile]
		for i in range(width*height):
			var t = Tile.new()
			tiles_1d.append(t)
		var s = Sublayer.new()
		s.tile_count = width * height
		s.tiles = MSDRoom.unflatten_tile_array(tiles_1d, width, height)
		return s

class Tile:
	var coords : int = 0
	var type : int  = 0
	var flipped_horizontally : bool  = false
	var rotated_90 : bool  = false
	var rotated_180 : bool  = false

	func read(data : StreamPeerBuffer):
		var tile_info = data.get_16() 
 
		coords = (tile_info & 0x07FF)
		type = ((tile_info & 0x1800) >> 11)
		if (type > 3):
			print("Type too large")
		flipped_horizontally = (tile_info & 0x2000) != 0
		rotated_90 = (tile_info & 0x4000) != 0
		rotated_180 = (tile_info & 0x8000) != 0
		

	func write(buf : StreamPeerBuffer):
		buf.put_16((coords) + (type << 11) + (0x2000 if flipped_horizontally else 0) + (0x4000 if rotated_90 else 0) + (0x8000 if rotated_180 else 0)) 
