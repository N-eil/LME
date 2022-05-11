extends Node
onready var layer_prefab = load("res://MSDLayer.tscn")
onready var object_placeholder_prefab = load("res://ObjectPlaceholder.tscn")
var mult_canvas = CanvasItemMaterial.new()
var add_canvas = CanvasItemMaterial.new()
const ROOM_WIDTH = 32
const ROOM_HEIGHT = 24


enum canvas_editing_types {
        NONE = 0,
        LAYERS = 1,
        OBJECTS = 2,
        COLLIION = 3
    }
    
var current_editing_type = 0

class Field:
    var name_size: int
    var objects_count: int
    var name: Array  # Array of bytes. Need to decode as UTF16 for text
    var objects: Array
    var rooms: Array

    var room_count : int
    var zone_id : int

    func _init(id):
        zone_id = id

    func add_screen(room_id): #TODO: Add screens to other places than just directly right
        room_count += 1
        rooms[room_id].add_screen(zone_id)

    func read(data : StreamPeerBuffer, msd : MSDMap):
        room_count = msd.room_count
        
        name_size = data.get_8()
        objects_count = data.get_16()
        name = data.get_data(name_size)[1]
        
        for i in range(objects_count):
            var o = ObjectWithoutPosition.new()
            o.read(data)
            objects.append(o)
            
        for i in range(room_count):
            var r = Room.new(i)
            var temp_screencount = msd.rooms[i].screen_count
            r.read(data, temp_screencount)
            rooms.append(r)
        
#        print("Read a zone with room count of %d an    d actual size %d" % [room_count, rooms.size()])
        
    func write(buf : StreamPeerBuffer):
        buf.put_8(name_size)
        buf.put_16(objects_count)
        buf.put_data(name)
        
        for o in objects:
            o.write(buf)
        for r in rooms:
            r.write(buf)
        
class Room:
    var room_object_count: int
    var room_objects: Array
    var screens: Array
    
    var screen_count : int
    var room_id : int
    
    func _init(id):
        room_id = id
    
    func add_screen(zone_id):#, screen_id):   TODO: add screens in other places
        var s = Screen.make_blank_screen()
        var screen_id = screen_count
        screen_count += 1
        var neighbouring_screen = screens[screen_id - 1] # TODO: fix other neighbour exits into the new screen too!  This can be hard since they are often in other rooms
        s.exits[1].copy_exit(neighbouring_screen.exits[1])
        s.exits[3] = Exit.new(zone_id, room_id, screen_id-1)
        
        neighbouring_screen.exits[1] = Exit.new(zone_id, room_id, screen_id)
        screens.append(s)
        
    func read(data : StreamPeerBuffer, screen_count: int):
        self.screen_count = screen_count
        
        room_object_count = data.get_16()
        for i in range(room_object_count):
            var o = ObjectWithoutPosition.new()
            o.read(data)
            room_objects.append(o)
        
        for i in range(screen_count):
            var s = Screen.new()
            s.read(data)
            screens.append(s)
        
    func write(buf : StreamPeerBuffer):
        buf.put_16(room_object_count)
        for o in room_objects:
            o.write(buf)
        for s in screens:
            s.write(buf)
                 
class Screen:
    var name_size: int
    var screen_object_count: int
    var without_position_count: int
    var screen_objects_without_position: Array
    var screen_objects: Array
    var screen_name: Array
    var exits: Array

    static func make_blank_screen():
        var s = Screen.new()
        s.name_size = 0
        s.screen_name = []
        s.screen_object_count = 0
        s.without_position_count =  0
        s.screen_objects_without_position = []
        s.screen_objects  =  []
        s.exits = []
        for i in range(4):
            s.exits.append(Exit.new())
        return s

    func add_pos_object(o):
        screen_object_count += 1
        screen_objects.append(o)

    func read(data : StreamPeerBuffer):

        name_size = data.get_8()
        screen_object_count = data.get_16()
        without_position_count = data.get_8()
        
        for i in range(without_position_count):
            var o = ObjectWithoutPosition.new()
            o.read(data)
            screen_objects_without_position.append(o)
            
        for i in range(screen_object_count - without_position_count):
            var o = ObjectWithPosition.new()
            o.read(data)
            screen_objects.append(o)
            
        screen_name = data.get_data(name_size)[1]
        
        for i in range(4):
            var e = Exit.new()
            e.read(data)
            exits.append(e)
        
    func write(buf : StreamPeerBuffer):
        buf.put_8(name_size)
        buf.put_16(screen_object_count)
        buf.put_8(without_position_count)
        
        for o in screen_objects_without_position:
            o.write(buf)
        for o in screen_objects:
            o.write(buf)
        buf.put_data(screen_name)
        
        for e in exits:
            e.write(buf)
            
class Exit:
    var zone_id: int
    var room_id: int
    var screen_id: int
   
    func _init(z = -1, r = -1, s = -1):
        zone_id = z
        room_id = r
        screen_id = s
    
    func copy_exit(source_exit):
        zone_id = source_exit.zone_id
        room_id = source_exit.room_id
        screen_id = source_exit.screen_id
    
    func read(data : StreamPeerBuffer):
        zone_id = data.get_8()
        room_id = data.get_8()
        screen_id = data.get_8()
        
    func write(buf : StreamPeerBuffer):
        buf.put_8(zone_id)
        buf.put_8(room_id)
        buf.put_8(screen_id)

    
class ObjectWithoutPosition:
    var object_id : int
    var number_of_test_flags : int
    var number_of_write_flags : int
    var number_of_parameters : int
    var test_byte_operations : Array
    var write_byte_operations : Array
    var parameters : Array
    
    func read(data : StreamPeerBuffer):
        object_id  = data.get_16()
        var number_of_flags = data.get_u8()
        number_of_test_flags = number_of_flags >> 4
        number_of_write_flags  = number_of_flags & 15
        number_of_parameters = data.get_8()
        
        for i in range(number_of_test_flags):
            var o = TestFlag.new()
            o.read(data)
            test_byte_operations.append(o)
        
        for i in range(number_of_write_flags):
            var o = WriteFlag.new()
            o.read(data)
            write_byte_operations.append(o)
            
        for i in range(number_of_parameters):
            var o = data.get_16()
            parameters.append(o)
            
    func write(buf : StreamPeerBuffer):
        buf.put_16(object_id)
        var number_of_flags = ((number_of_test_flags << 4) + number_of_write_flags)
        buf.put_8(number_of_flags)
        buf.put_8(number_of_parameters)
        
        for t in test_byte_operations:
            t.write(buf)
        for w in write_byte_operations:
            w.write(buf)
        for p in parameters:
            buf.put_16(p)
        
class ObjectWithPosition:
    var object_id : int
    var number_of_test_flags : int
    var number_of_write_flags : int
    var number_of_parameters : int
    var position_x : int
    var position_y : int
    var test_byte_operations : Array
    var write_byte_operations : Array
    var parameters : Array  
    
    func read(data : StreamPeerBuffer):
        object_id  = data.get_16()
        var number_of_flags = data.get_u8()
        number_of_test_flags = number_of_flags >> 4
        number_of_write_flags  = number_of_flags & 15
        number_of_parameters = data.get_8()
        position_x  = data.get_16()
        position_y  = data.get_16()
        
        for i in range(number_of_test_flags):
            var o = TestFlag.new()
            o.read(data)
            test_byte_operations.append(o)
        
        for i in range(number_of_write_flags):
            var o = WriteFlag.new()
            o.read(data)
            write_byte_operations.append(o)
            
        for i in range(number_of_parameters):
            var o = data.get_16()
            parameters.append(o)
        
    func write(buf : StreamPeerBuffer):
        buf.put_16(object_id)
        var number_of_flags = ((number_of_test_flags << 4) + number_of_write_flags)
        buf.put_8(number_of_flags)
        buf.put_8(number_of_parameters)
        buf.put_16(position_x)
        buf.put_16(position_y)
        
        for t in test_byte_operations:
            t.write(buf)
        for w in write_byte_operations:
            w.write(buf)
        for p in parameters:
            buf.put_16(p)
         
class TestFlag:
    var flag : int
    var value : int
    var operation : int
    
    func read(data : StreamPeerBuffer):
        flag = data.get_16()
        value = data.get_8()    
        operation  = data.get_8()
    
    func write(buf : StreamPeerBuffer):
        buf.put_16(flag)
        buf.put_8(value)
        buf.put_8(operation)
    
class WriteFlag:
    var flag : int
    var value : int
    var operation : int
    
    func read(data : StreamPeerBuffer):
        flag = data.get_16()
        value = data.get_8()    
        operation  = data.get_8()
    
    func write(buf : StreamPeerBuffer):
        buf.put_16(flag)
        buf.put_8(value)
        buf.put_8(operation)
       
const msd_graphics_map = ["map00_1.png", "map01_1.png",
     "map02_1.png", "map03_1.png", "map04_1.png", "map05_1.png", "map06_1.png", "map07_1.png", "map08_1.png", "map09_1.png", "map10_1.png", "map11_1.png", "map12_1.png", "map13_1.png", "map14_1.png", "map15_1.png",
     "map16_1.png", "map17_1.png", "", "", "", "", "", "", "", "", "", "", "", "map18_1.png", "map19_1.png", "map19_1.png"    
     ]
    
    
class MSDMap:
    var animated_tiles : Array
    var animated_tiles_end : int
    var graphics_id : int
    var unk : int
    var room_count : int
    var rooms : Array
    
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
        coords = data.get_16() #TODO: split this into bits
    
    func write(buf : StreamPeerBuffer):
        buf.put_16(coords)
    
class MSDRoom:
    var use_boss_graphics : bool
    var layer_count : int
    var prime_layer_index : int
    var hit_mask_width : int
    var hit_mask_height : int
    var hit_mask
    var layers : Array
    
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
            for i in range(32 *2):
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
        buf.put_16(hit_mask_width)
        buf.put_16(hit_mask_height)
        var flat_hit_mask = MSDRoom.flatten_tile_array(hit_mask)
        buf.put_data(flat_hit_mask)
        
        for l in layers:
            l.write(buf)
        
class Layer:
    var layer_width : int
    var layer_height : int
    var sublayer_count : int
    var sublayers : Array

    var tile_count : int
    var screen_count : int
    
    var horizontal_screen_count : int
    var vertical_screen_count : int
    var is_prime_layer : bool

    var horz_offsize = 0
    var vert_offsize = 0

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
#        print("Getting sublayer of size " + str(tile_count))
        for i in range(sublayer_count):
            var s = Sublayer.new()
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
    var tiles
    var tile_count : int
    
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
        
class Tile:
    var coords : int
    var type : int
    var flipped_horizontally : bool
    var rotated_90 : bool
    var rotated_180 : bool
    
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
    
        
export(String) var rcd_filename
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var loaded_rsd_buffer
var rsd_file = File.new()
var all_fields = []
var all_msd = []

#onready var current_directory = OS.get_executable_path().get_base_dir()
const TILESIZE = 20

const current_directory = "D:/la mulana editor/LME"
var msd_directory = current_directory.plus_file("MSD")
var graphics_directory = current_directory.plus_file("GRAPHICS")

func load_rcd():
    loaded_rsd_buffer = StreamPeerBuffer.new()
    rsd_file.open(current_directory.plus_file("originalscript.rcd"), File.READ)
    var temp_buffer = rsd_file.get_buffer(rsd_file.get_len())
#    print(temp_buffer.size())   
    loaded_rsd_buffer.put_data(temp_buffer)
    loaded_rsd_buffer.big_endian = true
    loaded_rsd_buffer.seek(0)
    loaded_rsd_buffer.get_16()

    rsd_file.close()

func write_rcd(file_to_write, output_buffer):
    file_to_write.store_buffer(output_buffer.data_array)

func load_msd(path, id, sizes_only = false):
    print("Reaing MSD " + path)
    var loaded_buffer = StreamPeerBuffer.new()
    var msd_file = File.new()
    print(msd_file.open(path, File.READ))
    var temp_buffer = msd_file.get_buffer(msd_file.get_len())
    print(temp_buffer.size())   
    loaded_buffer.put_data(temp_buffer)
    loaded_buffer.big_endian = true
    loaded_buffer.seek(0)

    var m = MSDMap.new()
    if (sizes_only):
        m.read_sizes(loaded_buffer, id)
    else:
        m.read(loaded_buffer, id)

    msd_file.close()
    return m



func load_graphics_to_tileset(path):
    var ts = TileSet.new()
    var tex : Texture = load(path)
    for id in range(2500):
        ts.create_tile(id)
        var r = Rect2(id%50 * TILESIZE, floor(id/50) * TILESIZE, TILESIZE, TILESIZE)
        ts.tile_set_texture(id, tex)
        ts.tile_set_region(id, r)
    return ts

var current_msd_file
var current_zone_id
var current_room_id
var current_screen_id

func convert_tile_coord_to_data(layer : Layer):
    pass
    
func screen_exists(z, r = 0, s = 0):
    if z >= all_fields.size():
        return false
    if r >= all_fields[z].room_count:
        return false
    if s >= all_fields[z].rooms[r].screen_count and all_fields[z].rooms[r].screen_count != 0:
        return false
    return true    
    
func _on_screen_selected(index):
    display_screen($RoomCanvas/Visuals, current_zone_id, current_room_id, index)
    display_objects_in_screen($RoomCanvas/Objects, current_zone_id, current_room_id, index)

func show_object_edit_menu(o):
    $EditType.current_tab = 2
    $EditType/Objects.object = o
    $EditType/Objects.display()
    $EditType.rect_size = Vector2(300,0)
    $EditType/Objects.visible = false
    $EditType/Objects.call_deferred("set_visible", true)
        
func display_objects_in_screen(location, zone_id, room_id, screen_id):
    for c in location.get_children():
        c.queue_free()
     
    if !screen_exists(zone_id, room_id, screen_id) or all_fields[zone_id].rooms[room_id].screen_count == 0:
        return

    var display_screen = all_fields[zone_id].rooms[room_id].screens[screen_id]
 
    for object in display_screen.screen_objects:
        var o = object_placeholder_prefab.instance()
        # TODO: Make this work for vertical rooms too
        o.position = Vector2(object.position_x - (screen_id * ROOM_WIDTH), object.position_y - (0 * ROOM_HEIGHT)) * TILESIZE
        o.object = object
        o.editor_ref = self
        location.add_child(o)

    var i = 2
    for object in display_screen.screen_objects_without_position:
        var o = object_placeholder_prefab.instance()
        o.position = Vector2(20, ROOM_HEIGHT * 20 + i * 32)
        o.object = object
        o.editor_ref = self
        location.add_child(o)
        i+=1
        
func display_room(location, zone_id, room_id):
    if (room_id == current_room_id and zone_id == current_zone_id):
        return
    if !screen_exists(zone_id, room_id):
        return
    current_room_id = room_id
    # Uncomment this line to load msd from game directory (loads the ones you previouslly saved instead of fresh ones)
#    var msd_directory = "C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data/mapdata"  
        
    var msd
    if (zone_id == current_zone_id):
        msd = current_msd_file
    else:
        current_zone_id = zone_id
        msd = load_msd(msd_directory.plus_file("map" + ("%02d" % zone_id) + ".msd"), zone_id)
        current_msd_file = msd
    
    
    
    $Node2D/RoomJump/HBoxContainer3/ScreenSelector.clear()
    for i in range(current_msd_file.rooms[room_id].screen_count):
        $Node2D/RoomJump/HBoxContainer3/ScreenSelector.add_item(str(i))
    
    current_screen_id = -1
    _on_screen_selected(0)

func display_screen(location, zone_id, room_id, screen_id):
    var screen_tile_set = load_graphics_to_tileset(graphics_directory.plus_file(current_msd_file.graphics_filename))
    if (screen_id == current_screen_id):
        return
    current_room_id = room_id if room_id != null else 0
    current_screen_id = screen_id if screen_id != null else 0
    
    for c in location.get_children():
        c.queue_free()

    var room = current_msd_file.rooms[current_room_id]

    
#    print(room.layer_count)
#    print(room.prime_layer_index)
    var layer_z = 100
    for layer in room.layers:
        var layer_node = Node2D.new()
        location.add_child(layer_node)
        layer_node.owner = location
        layer_z -= layer.sublayer_count
        layer_node.z_index = layer_z
#        var top_left = layer.get_top_left(screen_id)
        var top_left = layer.get_top_left_2d(screen_id)        
        
#    if true:
#        var layer = room.layers[room.prime_layer_index - 1]  ONLY SHOW PRIME LAYER
#        $RoomCanvas/TileMap.cell_size = Vector2(TILESIZE/2, TILESIZE/2)
#        var index = 0
#        for h in room.hit_mask:
#            if h:
#                tilemap.set_cell(index % room.hit_mask_width, floor(index / room.hit_mask_width), 0)
#            index += 1    
#        for s in range(layer.sublayers.size() -1, -1,-1):  REVERSE SUBLAYER ORDER
#            var sublayer = layer.sublayers[s]
        var sublayer_z = layer.sublayer_count
        for sublayer in layer.sublayers:
#            var index = 0

            var tilemap = layer_prefab.instance()
            tilemap.tile_set = screen_tile_set
            tilemap.cell_size = Vector2(TILESIZE, TILESIZE)
            tilemap.z_index = sublayer_z
            tilemap.set_process_input(99 == tilemap.z_index) #TODO: draw on all layers, not just primary
            layer_node.add_child(tilemap)
            sublayer_z -= 1
            if (layer.horizontal_screen_count < 1):
                tilemap.width = layer.layer_width
                tilemap.height = layer.layer_height
            
            var blend_set = false
            var types_in_layer = []
            var i = 0
            while i < 24:
                if (i >= layer.layer_height):
                    break
                var j = 0
                while  j < 32:
                    var flip_flags = [false, false, false]  
                    if (j >= layer.layer_width):
                        break                 
                    var tile = sublayer.tiles[top_left.y + i][top_left.x + j]
                    if tile.flipped_horizontally:
                        flip_flags[0] = !flip_flags[0]
                    if tile.rotated_90:
                        flip_flags[0] = !flip_flags[0]    
                        flip_flags[2] = !flip_flags[2]
                    if tile.rotated_180:
                        flip_flags[0] = !flip_flags[0]
                        flip_flags[1] = !flip_flags[1]                    
                    if tile.type != 0:
                        tilemap.set_cell(j, i, tile.coords, flip_flags[0], flip_flags[1], flip_flags[2])
                        if (!blend_set):
                            blend_set = true
                            if tile.type == 2:
                                tilemap.material = add_canvas
                            if tile.type == 3:
                                tilemap.material = mult_canvas
                                
                    if(!types_in_layer.has(tile.type)):
                        types_in_layer.append(tile.type)                
                    j += 1
                i += 1

        
# Called when the node enters the scene tree for the first time.
func _ready():
    add_canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    mult_canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
    
    load_rcd()

    
    for i in range(26):
        var f = Field.new(i)
        var msd = load_msd(msd_directory.plus_file("map" + ("%02d" % i) + ".msd"), i, true)
        f.read(loaded_rsd_buffer, msd)
        all_fields.append(f)
        if i >  15:
            print(i)
#        all_msd.append(msd)
#        display_room($RoomCanvas/TileMap, all_msd[0], 0, 0, 0)
    print("READING DONE")
    display_room($RoomCanvas/Visuals, 0, 0)
#    var temp_storage_file = File.new()
#    temp_storage_file.open("res://tempstore.json", File.WRITE)
#    temp_storage_file.store_string(JSON.print(all_fields, "  "))
#    temp_storage_file.close()   

    
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#    pass

func _on_Button_pressed():
    # TODO: deep clone instead of reference
#    all_fields[0].rooms[1].screens[1].exits[1].screen_id = 2
#    all_fields[0].rooms[1].screens.append(all_fields[0].rooms[1].screens[1])
#    all_fields[0].rooms[1].screens[2].exits[1].screen_id = 0
#    all_fields[0].rooms[1].screens[2].exits[1].room_id = 2

    clear_room_visuals(0,5) # Clears out a room for fun visual effects TODDO: Remove

    save_msd_changes()
    save_rcd_changes()
    
func save_msd_changes():
    var output_buffer = StreamPeerBuffer.new()
    output_buffer.big_endian = true
    output_buffer.seek(0)
    current_msd_file.write(output_buffer)

    var written_msd = File.new()
    var game_current_directory = "C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data/mapdata"
    written_msd.open(game_current_directory.plus_file("map" + ("%02d" % current_zone_id) + ".msd"), File.WRITE)
    written_msd.store_buffer(output_buffer.data_array)
    written_msd.close()

    print("MSD written!")

func save_rcd_changes():
    var write_file = File.new()
    var game_current_directory = "C:/Program Files (x86)/Steam/steamapps/common/La-Mulana/data/mapdata"
    write_file.open(game_current_directory.plus_file("script.rcd"), File.WRITE)    
    
    var output_buffer = StreamPeerBuffer.new()
    output_buffer.big_endian = true
    output_buffer.seek(0)
    output_buffer.put_16(0)
    
    for field in all_fields:
        field.write(output_buffer)
    write_rcd(write_file, output_buffer)
    print("RCD WRITTEN")
    write_file.close()


func _on_Jump_pressed():   
    display_room($RoomCanvas/Visuals, int($Node2D/RoomJump/HBoxContainer/ZoneEdit.text), int($Node2D/RoomJump/HBoxContainer2/RoomEdit.text))
    
func clear_room_visuals(zone_id, room_id):
    for layer in current_msd_file.rooms[room_id].layers:
        for sub in layer.sublayers:
            for r in sub.tiles:
                for t in r:
                    t.coords = 45
                    t.type = 1
                    
func cell_clicked(tilemap, position):
    var new_coords = 34
    var new_object = 0x08

    if current_editing_type == canvas_editing_types.LAYERS:
        add_visual_tile(tilemap, position,new_coords)
    elif current_editing_type == canvas_editing_types.OBJECTS:
        add_position_object(position, new_object)
    elif current_editing_type == canvas_editing_types.COLLIION:
        add_collision(position, current_msd_file.rooms[current_room_id])
             
func add_visual_tile(tilemap, position, new_coords, new_type = 1): 
    tilemap.set_cell(position.x, position.y, new_coords)

    var editing_room = current_msd_file.rooms[current_room_id]
    var editing_layer = editing_room.layers[editing_room.prime_layer_index-1] # TODO: Allow editing of different layers!
    var editing_sublayer = editing_layer.sublayers[editing_layer.sublayer_count-1] # TODO: Allow editing of any sublayer!
    var top_left = editing_layer.get_top_left_2d(current_screen_id)
    
    var editing_tile = editing_sublayer.tiles[position.y + top_left.y][position.x + top_left.x]   #current_screen_id) + position.x + (position.y * editing_layer.layer_width)
    
    editing_tile.coords = new_coords
    editing_tile.type = new_type

#    add_collision(position, editing_room)

func add_position_object(position, new_o):
    new_o.position_x = position.x
    new_o.position_y = position.y
    all_fields[current_zone_id].rooms[current_room_id].screens[current_screen_id].add_pos_object(new_o)

func add_collision(position, room, collision_type  = 0x80):  #TODO: More granular collision drawing!

    var top_left = room.get_hitmask_top_left(current_screen_id)
    
    # NOTE TO NEIL: the *2 exits because hitmask cells are half size.  if a hitmask draw mode is made, this might no longer be needed
    room.hit_mask[position.y*2 + top_left.y][position.x*2 + top_left.x] = collision_type
    room.hit_mask[position.y*2 + top_left.y + 1][position.x*2 + top_left.x] = collision_type
    room.hit_mask[position.y*2 + top_left.y][position.x*2 + top_left.x + 1] = collision_type
    room.hit_mask[position.y*2 + top_left.y + 1][position.x*2 + top_left.x + 1] = collision_type  
    

func _on_add_new_room_pressed():
    current_msd_file.rooms[current_room_id].add_screen(current_screen_id)
    all_fields[current_zone_id].rooms[current_room_id].add_screen(current_zone_id)

    $Node2D/RoomJump/HBoxContainer3/ScreenSelector.clear()
    for i in range(current_msd_file.rooms[current_room_id].screen_count):
        $Node2D/RoomJump/HBoxContainer3/ScreenSelector.add_item(str(i))
    
    current_screen_id = -1
    display_screen($RoomCanvas/Visuals, current_zone_id, current_room_id, 0)
    _on_screen_selected(all_fields[current_zone_id].rooms[current_room_id].screen_count -1)
