extends Node
var all_fields : Array[Field] = []
var all_screenplay : ScreenplayFull
var active_msd : MSDMap
var all_position_objects = {}
var all_nonposition_objects = {}

var current_graphics_filename : String

var sketchpad_window : Window 
var collisionpad_window : Window 

var mult_canvas := CanvasItemMaterial.new()
var add_canvas := CanvasItemMaterial.new()

var active_art_tile_index : int = 0
var active_collision_tile_index : int = 1
#  "flip_h": false, "rot_90": false, "rot_180": false
var tile_draw_settings = [false, false, false]
enum EditType {
	ART,
	ART_COPY,
	COLLISION,
	OBJECT,
	NONE
}
var current_edit_type : EditType = EditType.NONE : set = set_edit_type

var copy_top_left : Vector2i = Vector2i(-1,-1)

func _ready():
	Messages.connect("new_art_palette", update_selected_palette)
	Messages.connect("art_cell_selected", set_active_art_tile)
	Messages.connect("collision_cell_selected", set_active_collision_tile)

	add_canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mult_canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL

func update_selected_palette(e):
	current_graphics_filename = e

func set_edit_type(e):
	current_edit_type = e
	Messages.emit_signal("edit_type_changed", e)

func set_active_art_tile(i):
	active_art_tile_index = i

func set_active_collision_tile(i):
	active_collision_tile_index = i

func make_graphics_filename(f):
	return "res://GRAPHICS/" + f


# Notes and info about objects: (various links)
# https://discord.com/channels/242731826253266945/334765309904814080/698643338735124521
const OBJECT_REFERENCE = {
	"0x00": {
		"name": "pot",
		"parameter_count": 9,
		"parameter_descriptions": [
			"Drop type",
			"Quantity",
			"Byte",
			"Bit (> 8 ok)",
			"Pot Type",
			"Hit Sound",
			"Break Sound",
			"Land Sound",
			"Pitch Shift"
		],
		"notes": "Drop type 1 = money, 2 = weights. weights cannot be higher than 1 quantity\n    Pitch shift is 48 000 Hz + shift * 10 Hz. That is, a shift of -500 will cause the sound effects to play at 43kHz, and a shift of 499 will cause the sound effects to play at 52 990 Hz. For pots, the pitch shift is varied randomly with each time a sound is played.",
		"write_flag_notes": ""
	},
	"0x07": {
		"name": "DynamicLadder",
		"parameter_count": 8,
		"parameter_descriptions": [
			"(0-1) 0 = From Top, 1 = From Bottom ",
			"(4-18) Height in graphical tiles",
			"(0-2) Graphic <=1 Map >1 eveg",
			"(0) (unused?)",
			"(360-900) ImageX",
			"(0-720) ImageY",
			"(0-1) Ladder type 0 = Standard, 1 = Philosopher",
			"(0-1) 0 = collision starts two hit tiles below (for platforms), 1 = collision starts at top"
		],
		"notes": "\tTest flag 0 - 0 folded\n\t              1 unfolding -> 2\n\t              2 unfolded\n\t\t\t\t  3 folding -> 0\n \n",
		"write_flag_notes": ""
	},
	"0x08": {
		"name": "trigger-dais",
		"parameter_count": 10,
		"parameter_descriptions": [
			"(0-1) Light red dust or pink dust",
			"(1-270) Falling time (in frames?)",
			"(-1-50) RiseFlag -1 Never Rise. 0 Always Rise",
			"(0-2) Image",
			"(0) (unused?)",
			"(180-860) ImageX",
			"(0-100) ImageY",
			"(0-1) Width 0 = Half-width, 1 = Full-width",
			"(0-10) (probably unused height)",
			"(0-60) RiseSpeed"
		],
		"notes": " \n",
		"write_flag_notes": ""
	},
	"0x09": {
		"name": "DynamicWall",
		"parameter_count": 6,
		"parameter_descriptions": [
			"(0) (UNUSED)",
			"(3-4) Height",
			"(2) Image <=1=mapXX_1.png 2=3=evegXX.png >3=02comenemy.png",
			"(0) (UNUSED)",
			"(420-800) ImageX",
			"(0-240) ImageY"
		],
		"notes": "\tWrite flags:\n\t\t0 - equality = open\n\t\t1 - set on open\n\t\t2 - equality = close\n\t\t3 - set on close\n\n",
		"write_flag_notes": ""
	},
	"0x0A": {
		"name": "roomspawner-move-nocollision",
		"parameter_count": 31,
		"parameter_descriptions": [
			"0",
			"Direction",
			"ShakeDirection 0=vertical 1=horizontal",
			"Distance (px)",
			"0|10|20|50|100 StartShakeSpeed",
			"Vi",
			"dV",
			"Vf",
			"0|1|50|100|200 EndShakeSpeed",
			"ReturnStartShakeSpeed",
			"Return Vi",
			"Return dV",
			"Return Vf",
			"ReturnEndShakeSpeed",
			"Layer",
			"Image 1=mapxx.png 2=3= evegxx.png 4=msd room",
			"Room Number",
			"ImageX",
			"ImageY",
			"dX",
			"dY",
			"Activation Sound Effect (same as file number)",
			"Sound Repeat Delay      (frames before playing effect again)",
			"Volume                  (0-127)",
			"Balance                 (0-127, 64 is centered)",
			"Pitch                   (see 0x9b for more details)",
			"Return Sound Effect     (as above.)",
			"Sound Repeat Delay2     (as above.)",
			"Volume2                 (as above.)",
			"Balance2                (as above.)",
			"Pitch2                  (as above.)"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0x0B": {
		"name": "flagTimer no position",
		"parameter_count": 2,
		"parameter_descriptions": [
			"Seconds",
			"Frames"
		],
		"notes": "    // Performs all updates after time specified.\n    \n",
		"write_flag_notes": ""
	},
	"0x0C": {
		"name": "Moving Platform",
		"parameter_count": 18,
		"parameter_descriptions": [
			"Tile Sheet map=0,1 eveg=2",
			"(0-980) TileX",
			"(0-562) TileY",
			"(20-200) dX",
			"(20-120) dY",
			"(0-6) Displaces the platform sprite number of pixels left. Setting too high can break vertical platforms",
			"(0-20) Displaces the platform sprite num pixels up. Interferes with vert. screen transitioning standing on platform. Setting too high can break horiz platforms",
			"(20-200) hitbox width",
			"(20-120) hitbox height",
			"(-1-1980) Platform left bound in Tile-Block (-1 causes horizontal platforms to wrap around the screen, like the one in hell temple)",
			"(80-1320) Platform upper bound in Tile-Block (-1 causes vertical platforms to wrap)",
			"(0-520) How far the platform moves right. Setting too low can break vertical platforms",
			"(40-1120) How far the platform moves down. Setting too low can break horizontal platforms",
			"(0-270) Platform Direction (angle CW from x direction)",
			"(0-1) 0 = Stops when it reaches the edge on the side, 1 = moves back and forth",
			"(0-1) ??",
			"(0-1) ??",
			"(100-240) Platform Speed"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0x0D": {
		"name": "cycleTimer no position",
		"parameter_count": 2,
		"parameter_descriptions": [
			"seconds",
			"frames"
		],
		"notes": "    //Performs one update and resets timer\n    //always performs the next update in sequence.\n    Update1\n    Update2\n    Update3\n    Update4\n    \n",
		"write_flag_notes": ""
	},
	"0x0E": {
		"name": "roomspawner",
		"parameter_count": 14,
		"parameter_descriptions": [
			"Room",
			"Destination layer",
			"UseHitMap",
			"Entry Effect",
			"Exit Effect",
			"Use ARGB Cycle",
			"dA",
			"Min A",
			"dR",
			"Max R",
			"dG",
			"Max G",
			"dB",
			"Max B"
		],
		"notes": "      0:Normal\n        1:Fade\n        2:Large Break\n        3:Crack-Break\n        4:Also Fade\n        5:Go white and vanish in a puff\n        6:Go Black and vanish in a puff\n        7:Go Red and do that streak dealie\n        8:Glow white + rising white pixels\n        9:Break Glass\n\n",
		"write_flag_notes": ""
	},
	"0x0F": {
		"name": "One way door ",
		"parameter_count": 5,
		"parameter_descriptions": [
			"Direction FromLeft,FromRight",
			"UNUSED",
			"Image: 0=mapxx_1.png 1=evegxx.png 2=00prof.png 3=02comenemy.png 4=6=00item.png 5=01menu.png 6=4=00item.png Default:01effect.png",
			"ImageX",
			"ImageY"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x10": {
		"name": "spikes-static",
		"parameter_count": 8,
		"parameter_descriptions": [
			"from up",
			"from right",
			"from down",
			"from left",
			"horiz size in tiles",
			"vert size in tiles",
			"% or hp",
			"damage (15)"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x11": {
		"name": "Crusher",
		"parameter_count": 31,
		"parameter_descriptions": [
			"UNUSED",
			"Direction URDL",
			"Width (dX for U,D. dY for R,L.) Measured in gtiles.",
			"Length (dY for U,D. dX for R,L.) Measured in gtiles.",
			"Activation Delay ",
			"Vi-extend * 100 ",
			"dV-extend * 100 ",
			"Vf-extend * 100 ",
			"Update1Delay ",
			"RetractDelay ",
			"Vi-retract * 100",
			"dV-retract * 100",
			"Vf-retract * 100",
			"Update2Delay ",
			"GraphicSheet ",
			"Room Number",
			"Image X",
			"Image Y",
			"Image dX",
			"Image dY",
			"Tile Fill switch",
			"layer",
			"Min Length",
			"Active Sound    (as sfx file number)",
			"RepeatDelay     (number of frames before playing sound again)",
			"Volume          (0-127)",
			"Pitch           (sample rate. Sound effect is played at 48 000Hz + pitch * 10Hz. Negative is ok.)",
			"Retract Sound   (as above.)",
			"Repeat Delay    (as above.)",
			"Volume          (as above.)",
			"Pitch           (as above.)"
		],
		"notes": "\n        <2=mapxx_1.png \n        2=3=evegxx.png \n        >4=msd Room\n        0: 0x80 wall + dynamic object\n        1: 0x20 waterfall\n        2: 0x05 water\n        3: 0x06 water flow UP\n        4: 0x08 water flow DOWN\n        5: 0x09 water flow LEFT\n        6: 0x07 water flow RIGHT\n        7: 0x20 waterfall\n        8: 0x10 lava\n        9: 0x11 lava flow UP\n        10:0x13 lava flow DOWN\n        11:0x14 lava flow LEFT\n        default:0x12 lava flow RIGHT\n\n",
		"write_flag_notes": ""
	},
	"0x12": {
		"name": "Hitbox generator (walls you can hit)",
		"parameter_count": 12,
		"parameter_descriptions": [
			"visual 1:dust >1: star",
			"0:hp 1:hits",
			"health",
			"direction: 0",
			"weapon type: 0-15 same as word, 16 all main 17 all sub 18 all 19 none",
			"Update Type ",
			"hitbox sizex",
			"hitbox sizey",
			"Hit Success Sound Effect (-1 for silent)",
			"Hit Fail Sound Effect (-1 for silent)",
			"dust1 density 1",
			"dust2 density 2             "
		],
		"notes": "        0-  break: update all 4.\n            wrongwep: update none.\n        1-  break: update 0,2\n            wrongwep: update 1,3\n\n",
		"write_flag_notes": ""
	},
	"0x13": {
		"name": "Really bad hitbox code",
		"parameter_count": 4,
		"parameter_descriptions": [
			"Hits per update",
			"DetectedMainWeapon 0-7",
			"gTile Width",
			"gTile Height"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x14": {
		"name": "detection-lemeza",
		"parameter_count": 6,
		"parameter_descriptions": [
			"seconds wait",
			"frames wait",
			"continuous/total",
			"interaction type 0 = any time except paused 1 = 2 = 3 = 4 = just be on the ground, ok. default: sleep",
			"graphical tile width",
			"graphical tile height\t"
		],
		"notes": "\trange:\n\tx+10 < lemeza+20 <= x+width - 10\n\ty+14 < lemeza+24 <= y+height - 18 // slightly above center\n\n",
		"write_flag_notes": ""
	},
	"0x22": {
		"name": "effect-shine 22 ct",
		"parameter_count": 12,
		"parameter_descriptions": [
			"01effect.mdd selector",
			"Layer",
			"Width",
			"Height",
			"AlphaFadeIN duration",
			"AlphaFadeOUT duration",
			"StartAlpha",
			"MaximumAlpha",
			"EndAlpha (bugs?)",
			"MaxAlphaTime",
			"SpinCCWSpeed",
			"SpinCWSpeed"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x23": {
		"name": "effect-steam 29 ct",
		"parameter_count": 26,
		"parameter_descriptions": [
			"1",
			"DustPuff or SteamPuff",
			"Layer",
			"Width (larger is more diffuse)",
			"Height",
			"SteamPuffSpawnInterval",
			"SteamPuffsPerInterval",
			"InitialAlphaDieMaxValue",
			"MaximumAlphaDieMaxValue (<=arg7 causes div by 0 error)",
			"MinimumInitialSize",
			"MaximumInitialSize (will not shrink)",
			"MinimumFinalSize",
			"MaximumFinalSize",
			"MinimumDurationDie",
			"MaximumDuration",
			"MinimumXDrift * 100",
			"MaximumXDrift * 100",
			"MaximumXacceleration",
			"MinimumXacceleration (cannot go opposite direction)",
			"MinimumYDrift * 100",
			"MaximumYDrift * 100",
			"MaximumYSpeed",
			"MinimumYSpeed? (cannot go opposite direction)",
			"1",
			"0",
			"1"
		],
		"notes": "    cannot update\n\n",
		"write_flag_notes": ""
	},
	"0x24": {
		"name": "effect-ghostscream (Seen in Ghost Lord room only) 3 ct",
		"parameter_count": 2,
		"parameter_descriptions": [
			"DestinationX",
			"DestinationY"
		],
		"notes": "        Position\n        Warning: entering a screen while ghost scream passes\n        tests crashes the game.\n\n",
		"write_flag_notes": ""
	},
	"0x25": {
		"name": "effect-dustparticle 16 ct",
		"parameter_count": 8,
		"parameter_descriptions": [
			"layer",
			"width",
			"height",
			"Count",
			"R",
			"G",
			"B"
		],
		"notes": "    cannot update\n    0 -\n    \n",
		"write_flag_notes": ""
	},
	"0x2B": {
		"name": "misc-sun-sphinx",
		"parameter_count": 3,
		"parameter_descriptions": [
			"Frames per shot",
			"Shot Speed",
			"Shot Damage"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0x2C": {
		"name": "item-treasurechest",
		"parameter_count": 6,
		"parameter_descriptions": [
			"item type, 1-10 are drop types, 11+ are inventory word",
			"if drop then quantity, if item then item arg 2 (whether it's a real item)",
			"if 0 then brown else blue",
			"if >0, cursed",
			"if 0 then flat curse damage else percentage",
			"curse damage"
		],
		"notes": "                // op not used\n                // op not used\n                // if chest has drop then performed on drop\n                // if chest is empty then performed when chest is opened\n                \n",
		"write_flag_notes": "    update 0    // if world[idx] == val then set chest to empty (creation and every frame)\n    update 1    // if world[idx] == val then set chest to ajar (creation and every frame)\n    update 2    // performed when chest is opened\n    update 3    // if chest has item then performed on item pickup\n"
	},
	"0x2D": {
		"name": "Weapon Cover",
		"parameter_count": 1,
		"parameter_descriptions": [
			"i doubt it"
		],
		"notes": "    Update0: Greater than, animate.\n    Update1: On destroy\n    Update2: On attack\n\n",
		"write_flag_notes": ""
	},
	"0x2E": {
		"name": "Ankh",
		"parameter_count": 32,
		"parameter_descriptions": [],
		"notes": "    Ask SeerSkye. I don't have the specifics.\n\t0 - Boss number.\n\t\t0-15 are valid, but bosses > 8 crash the game. (missing files?)\n\t\t\n\t\t0 = amphisbaena\n\t\t1 - (0-1) Speed\n\t\t2 - (32-48) Health\n\t\t3 - (16-24) Contact Damage\n\t\t4 - (1-2) Flame Speed\n\t\t5 - (6-12) Flame Damage\n\t\t6 - (0)\n\t\t7 - (0)\n\t\t8 - (0)\n\t\t9 - (0)\n\t\t10 - (0)\n\t\t11 - (0)\n\t\t12 - (0)\n\t\t13 - (0)\n\t\t14 - (0)\n\t\t15 - (0)\n\t\t16 - (0)\n\t\t17 - (0)\n\t\t18 - (0)\n\t\t19 - (0)\n\t\t20 - (0)\n\t\t21 - (0)\n\t\t22 - (0)\n\t\t23 - (0)\n\t\t\n\t\t1 = Sakit\n\t\t1- (2) Speed\n\t\t2- (45-64) Heath\n\t\t3- (16-32) Contact and chain-punch damage\n\t\t4- (2-1) Orb Proj Speed\n\t\t5- (8-16) Orb Damage\n\t\t6- (60) Orb Charge Time\n\t\t7- (16-24) Chain Recoil and Flame Damage\n\t\t8- (20-24) Phase 2 Health\n\t\t9- (85-75) Phase 2 delay between actions\n\t\t10- (1-2) Rocket punch speed\n\t\t11- (24-32) Rocket Punch damage\n\t\t12- (470) Flag set at beginning of fight to remove both statues\n\t\t13- (1) Flag value\n\t\t14- (3) Falling rock damage\n\t\t15- (0-1) Split-rock damage\n\t\t16- (0)\n\t\t17- (0)\n\t\t18- (0)\n\t\t19- (0)\n\t\t20- (0)\n\t\t21- (0)\n\t\t22- (0)\n\t\t23- (0)\n \n\t\t2 = Ellmac\n\t\t1 - (2-3) Speed\n\t\t2 - (54-72) Health\n\t\t3 - (18-32) Contact Damage\n\t\t4 - (2) Proj Speed\n\t\t5 - (8-16) Proj Damage\n\t\t6 - (16-32) Proj lingering flame damage\n\t\t7 - (40-64) Charge Damage\n\t\t8 - (200-150) Action cooldown\n\t\t9 - (32-24) Affects track segments?\n\t\t10 - (64-48) Track segment length?\n\t\t11 - (14000) Track speed\n\t\t12 - (30-36) Enrage heath threshold\n\t\t13 - (10-20) Enrage speed increase (higher is faster)\n\t\t14 - (67) Flag to set (removes trolley)\n\t\t15 - (0)\n\t\t16 - (0)\n\t\t17 - (0)\n\t\t18 - (0)\n\t\t19 - (0)\n\t\t20 - (0)\n\t\t21 - (0)\n\t\t22 - (0)\n\t\t23 - (0)\n \n\t\t3 = Bahamut\n\t\t1 - (2-3) Speed\n\t\t2 - (42-64) Health\n\t\t3 - (24-32) Contact Damage\n\t\t4 - (2) Proj speed\n\t\t5 - (16-32) Proj Damage\n\t\t6 - (24-32) Cheese-ball damage\n\t\t7 - (50) Number of cheese-balls\n\t\t8 - (90-45) Delay between attacks\n\t\t9 - (24-32) Enrage Health threshold\n\t\t10 - (85-80) Controls enrage speed increase, lower is faster\n\t\t11 - (67) Flag (removes boat)\n\t\t12 - (0)\n\t\t13 - (0)\n\t\t14 - (0)\n\t\t15 - (0)\n\t\t16 - (0)\n\t\t17 - (0)\n\t\t18 - (0)\n\t\t19 - (0)\n\t\t20 - (0)\n\t\t21 - (0)\n\t\t22 - (0)\n\t\t23 - (0)\n\t\t\n\t\t4 = Viy\n\t\t1 - (2) Speed\n\t\t2 - (80-100) Health\n\t\t3 - (16-24) Contact Damage\n\t\t4 - (500-700) Vertical Speed\n\t\t5 - (4-6) Tentacle Health\n\t\t6 - (1-2) Tentacle Speed and Damage\n\t\t7 - (8-16)\n\t\t8 - (1800-1200) Tentacle Respawn Time\n\t\t9 - (1) Eye Flame Proj Speed\n\t\t10 - (6-12) Eye flame damage\n\t\t11 - (2-3) Eye Laser Speed\n\t\t12 - (24-32) Eye Laser Damage\n\t\t13 - (100-80) Large Laser Charge Time\n\t\t14 - (90) Large Laser Damage\n\t\t15 - (4-6) Minion Health\n\t\t16 - (3-6) Minion Damage\n\t\t17 - (864) Flag to set (to break floor)\n\t\t18 - (1) Val to set flag to\n\t\t19 - (40-50) Health threashold to enrage\n\t\t20 - (85-75) Enrage speed increase (lower = faster)\n\t\t21 - (0)\n\t\t22 - (0)\n\t\t23 - (0)\n \n\t\tPalenque Ankh\n\t\t1 - (1-2) Speed\n\t\t2 - (100-120) Health\n\t\t3 - (64-80) Contact Damage\n\t\t4 - (1-2) Laser Turret Speed\n\t\t5 - (6-12)\n\t\t6 - (30-20) How quickly lasers are fired, also how long the lasers are\n\t\t7 - (10-24) laser turret damage\n\t\t8 - (5-10)\n\t\t9 - (32-64)\n\t\t10 - (48-80)\n\t\t11 - (1) Forward bullet spray speed\n\t\t12 - (8-16) Forward Bullet Spray Damage\n\t\t13 - (2) Lobbed Bullet speed\n\t\t14 - (16-24) Lobbed bullet damage\n\t\t15 - (24-32) Lobbed bullet lingering flame damage\n\t\t16 - (80-100) Charge Damage\n\t\t17 - (13) Flag to check for starting plane appearance\n\t\t18 - (90-60) Laser Duration\n\t\t19 - (64-100) Laser Damage\n\t\t20 - (12) Flag to set to open mural\n\t\t21 - (4-5) Wall health\n\t\t22 - (24-48) Wall crash damage\n\t\t23 - (0)\n\t\t \n\t\tBaphomet Ankh\n\t\t1 - (2-3) Speed\n\t\t2 - (200-240) Health\n\t\t3 - (32-64) Contact Damage\n\t\t4 - (2-3) Lightning Speed\n\t\t5 - (24-48) Lightning Damage\n\t\t6 - (1) Flame Speed\n\t\t7 - (16-32) Flame Damage\n\t\t8 - (2) 1st phase shooty orb speed\n\t\t9 - (32-64) orb damage\n\t\t10 - (1-2) Phase 2 orb speed\n\t\t11 - (16-32) Phase 2 orb damage\n\t\t12 - (90-60) Delay between phase 2 lightning\n\t\t13 - (2700-1800) Witch respawn time\n\t\t14 - (80-100) Health threshold for phase change\n\t\t15 - (55) Flag to set (breaks platform)\n\t\t16 - (1) Flag value\n\t\t17 - (5-6) Witch health\n\t\t18 - (2) Witch speed\n\t\t19 - (4-6) Witch contact damage\n\t\t20 - (2) Witch proj speed\n\t\t21 - (6-8) Witch proj main damage\n\t\t22 - (6-8) Witch Lingering flame damage\n\t\t23 - (6-8) Witch split orb damage\n\t\t \n\t\tTiamat Ankh\n\t\t1 - (2-3) Speed\n\t\t2 - (260-300) Health\n\t\t3 - (32-64) Contact Damage\n\t\t4 - (0-1) Red Fireball Speed\n\t\t5 - (12-24) Red Fireball damage\n\t\t6 - (2) Blue Fireball Speed\n\t\t7 - (24-32) Blue fireball damage\n\t\t8 - (1-2) Purple fireball speed\n\t\t9 - (32-48) Purple fireball damage\n\t\t10 - (120-180) Waterfall Damage\n\t\t11 - (150-200) Big Laser damage\n\t\t12 - (12-24) Green Laser damage\n\t\t13 - (70-55) Laser duration/length\n\t\t14 - (3) Purple spray proj speed\n\t\t15 - (16) Purple spray damage\n\t\t16 - (200-260) 2nd phase health threshold\n\t\t17 - (100-160) 3rd phase health threshold\n\t\t18 - (55) Flag to set at beginning of fight (removes red glowing circles)\n\t\t19 - (1) Flag value\n\t\t20 - (61) Flag that makes the doors move\n\t\t21 - (64) Flag that makes tiamat spawn\n\t\t22 - (0)\n\t\t23 - (0)\n\t1 -\n\t2 -\n\t3 -\n\t4 -\n\t5 -\n\t6 -\n\t7 -\n\t8 -\n\t9 -\n\t10-\n\t11-\n\t12-\n\t13-\n\t14-\n\t15-\n\t16-\n\t17-\n\t18-\n\t19-\n\t20-\n\t21-\n\t22-\n\t23-\n\t24-  Victory Field (-1 for same as Ankh)\n\t25-  Victory Room & Screen (-1 for same as Ankh) (decimal number in the form XXYY where XX = target room and YY = target screen)\n\t26- Victory XY (x*100 + y; graphical tiles.)\n\t27- Victory Splat animation (0 = Normal, 1 = Splat from position, 2 = splat from top of screen, 3 = splat flowing left, 4 = splat flowing right, 5+ = no splat, place lemeza near top-left of screen, fail to load graphics)\n\t28- Defeat Field (Defeat meaning when you get kicked out of Palenque and Mother)\n\t29- Defeat Room & Screen \n\t30- Defeat Combined x-y position\n\t31- Defeat Splat animation\n\n",
		"write_flag_notes": ""
	},
	"0x2F": {
		"name": "item-naked",
		"parameter_count": 3,
		"parameter_descriptions": [
			"0 = spawn interactable 1 = interactable 30 frames after spawn 2 = spawned from a chest",
			"inventory word",
			"if >0 add to inv, play sound, otherwise just sets flags"
		],
		"notes": "    ptr 0    // spawning chest\n    \n",
		"write_flag_notes": ""
	},
	"0x30": {
		"name": "Trapdoor",
		"parameter_count": 5,
		"parameter_descriptions": [
			"FlagOpen (0 is no flag)",
			"FramesWaitBeforeTrap | DesiredFlagVlaue",
			"FramesOpenAfterAnimation",
			"ImageX",
			"ImageY"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x31": {
		"name": "Always on Turret (spawned by turret)",
		"parameter_count": 4,
		"parameter_descriptions": [
			"Direction",
			"Shot Type",
			"Wait between volleys",
			"Wait between Shots",
			"Shots per volley",
			"Projectile Speed",
			"Shot Damage",
			"Projectile Graphic Offset",
			"Projectile Graphic Offset"
		],
		"notes": "\n\n",
		"write_flag_notes": ""
	},
	"0x32": {
		"name": "trigger-button-stand",
		"parameter_count": 11,
		"parameter_descriptions": [
			"y offset",
			"sink frames",
			"rise frames",
			"type. 0: Lemeza activates 1: Enemy Activates 2: Enemy + Lemeza Activates 3+ ???",
			"if <=1 then map else eveg",
			"tex u",
			"tex v",
			"tex width",
			"tex height",
			"detection size (centered)"
		],
		"notes": "\n",
		"write_flag_notes": "    update 0 // (test) if world[idx]==val then active else inactive\n    update 1 and 3 when deactivated if initially active\n    update 2 when activated if initially deactivated\n"
	},
	"0x33": {
		"name": "Counterweight-Elevator",
		"parameter_count": 23,
		"parameter_descriptions": [
			" TODO affects something while locked",
			" activation force (10x fall speed + 10 for lemeza, various numbers for enemies and the cart) (cpx/f)",
			" fully set y offset",
			" minimum force to keep set (cpx/f)",
			" max descending speed (cpx/f)",
			" max ascending speed (cpx/f)",
			" texture if <= 1 then map else eveg",
			" tex u",
			" tex v",
			" tex width",
			" tex height",
			" solid width",
			" solid height",
			" drawing layer offset (if negative, -arg[14]*2, if >= 0 && <= 10 +arg[14], if >10 +arg[14]*2",
			" descending sfx",
			" descending sfx delay    (number of frames before repeating sound)",
			" descending sfx volume   (range is 0-127)",
			" descending sfx pitch    (sound effect is played at 48 000 Hz + pitch * 10 Hz)",
			" ascending sfx",
			" ascending sfx delay     (as descending)",
			" ascending sfx volume    (as descending)",
			" ascending sfx pitch     (as descending)"
		],
		"notes": "    0 -\n    upd  0  equality test, unlocks mechanism\n    upd  1  performed when set\n    upd  2  performed when released\n    upd  3  performed when set\n\n    sta  0  unset\n    sta  1  activation threshold exceeded (for half a frame between queuedraw and update, pause glitchable)\n    sta  2  set\n    sta  3  deactivation threshold passed (for half a frame between queuedraw and update, pause glitchable)\n    sta  4  moving\n    sta  5  tests failed, locked\n\n    flt  1  width\n    flt  2  current y offset\n    flt  3  tex u\n    flt  4  tex v\n    flt  5  tex w\n    flt  6  tex h\n    flt  7  depressed y offset\n    flt  8  max descending speed (px/f)\n    flt  9  max ascending speed (px/f)\n    flt 11  force to keep set (px/f)\n    flt 12  activation threshold (px/f)\n    flt 13  y velocity\n    flt 14  height\n\n\n",
		"write_flag_notes": ""
	},
	"0x34": {
		"name": "trigger-seal",
		"parameter_count": 2,
		"parameter_descriptions": [
			"SealNumber (0 indexed)",
			"True:UseMomSeal"
		],
		"notes": "    \n\n    \n",
		"write_flag_notes": ""
	},
	"0x72": {
		"name": "stub",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "    it does nothing\n                \n",
		"write_flag_notes": ""
	},
	"0x91": {
		"name": "fairy-point",
		"parameter_count": 1,
		"parameter_descriptions": [
			"0 normal 1 Health 2 Attack 3 Luck 4 Key"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x92": {
		"name": "VFX-fog Room-wide visual effect. Extinction Darkness. Eden Fog. Twins Poison.",
		"parameter_count": 22,
		"parameter_descriptions": [
			"Move Direction clockwise right. 0: No movement.",
			"film grain speed = arg%50. fog speed = arg/100",
			"maximum SRC alpha range: 0-255",
			"minimum SRC alpha",
			"frames per 1 alpha",
			"UNUSED",
			"SRC Alpha Fade Control ",
			"Blend Mode Default Value",
			"Blend Mode-SRC",
			"Blend Mode-DEST",
			"UNUSED",
			"UNUSED",
			"fogXX.png",
			"Pattern Select (0-5)",
			"SRC Red",
			"SRC Green",
			"SRC Blue",
			"t/f lemeza spotlight (remains white)",
			"UNUSED",
			"UNUSED",
			"UNUSED",
			"UNUSED"
		],
		"notes": "        0:Increase to max,stop. \n        1: Increase to max,reset to min \n        2: Increase,Decrease \n        Default: it's not happy\n\n\n8: 0:D3DBLEND_ZERO\n     D3DBLEND_ONE\n     D3DBLEND_DESTCOLOR\n     D3DBLEND_INVDESTCOLOR\n     D3DBLEND_SRCALPHA\n     D3DBLEND_INVSRCALPHA\n     D3DBLEND_DESTALPHA\n     D3DBLEND_INVDESTALPHA\n     \n9: 0-D3DBLEND_ZERO\n     D3DBLEND_ONE\n     D3DBLEND_INVSRCCOLOR\n     D3DBLEND_SRCCOLOR\n     D3DBLEND_SRCALPHA\n     D3DBLEND_INVSRCALPHA\n     D3DBLEND_DESTALPHA\n     D3DBLEND_INVDESTALPHA\n\n",
		"write_flag_notes": ""
	},
	"0x93": {
		"name": "Texture draw",
		"parameter_count": 24,
		"parameter_descriptions": [],
		"notes": "     0 - Layer\n     1 - Image 0=mapxx_1.png 1=evegxx.png 2=00prof.png 3=02comenemy.png 4=6=00item.png 5=01menu.png 6=4=00item.png Default:01effect.png\n     2 - Imagex\n     3 - Imagey\n     4 - dx\n     5 - dy\n     6 - 0:act as if animation already played\n         1:allow animation\n         2:..?\n     7 - Animation Frames\n     8 - Pause Frames\n     9 - Repeat Count (<1 is forever)\n    10 - Hittile to fill with\n    11 - Entry Effect\n         0-static (default)\n         1-Fade\n         2-Animate; show LAST frame.\n         \n    12 - Exit Effect\n         0-disallow animation\n         1-Fade\n         2-Default\n         3-Large Break on Completion/Failure\n         4-Default\n         5-Animate on failure, frame 1 on success\n         6-Break Glass on Completion/Failure\n         Default: Disappear Instantly\n    13 - Cycle Colors t/f\n    14 - Alpha/frame\n    15 - Max Alpha\n    16 - R/frame\n    17 - Max R\n    18 - G/frame\n    19 - Max G\n    20 - B/frame\n    21 - Max B\n    22 - blend. 0=Normal 1=add 2= ... 14=\n    23 - not0?\n\n\n    arg13 != 0:\n        (255-arg15)/arg14   A\n        arg17/arg16         R\n        arg19/arg18         G\n        arg21/arg20         B\n        if second is 0, then 0 is the result\n    \n",
		"write_flag_notes": ""
	},
	"0x94": {
		"name": "detection-collapsing floor",
		"parameter_count": 4,
		"parameter_descriptions": [
			"seconds",
			"frames",
			"cumulative t/f",
			"gtile width"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x95": {
		"name": "Eye of Divine Retribution",
		"parameter_count": 3,
		"parameter_descriptions": [
			"10 ",
			"0  ",
			"30 "
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x96": {
		"name": "spikes-extend",
		"parameter_count": 26,
		"parameter_descriptions": [
			"Layer",
			"Direction URDL",
			"Width-Extended (unused)",
			"Length-Extended",
			"Activation Delay",
			"Vi-extend * 100",
			"dV-extend * 100",
			"Vf-extend * 100",
			"Update1Delay",
			"RetractDelay",
			"Vi-retract * 100",
			"dV-retract * 100",
			"Vf-retract * 100",
			"Update2Delay",
			"GraphicSheet 0=mapxx_1.png 1=evegxx.png 2=00prof.png 3=02comenemy.png 4=6=00item.png 5=01menu.png 6=4=00item.png 7=01effect.png Default=msd Room",
			"Room Number",
			"ImageX",
			"ImageY",
			"dx",
			"dy",
			"ExtendSound",
			"RetractSound",
			"DamageType 0%, 1hp",
			"Damage",
			"SideDamage?",
			"0, *20*, 40"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0x97": {
		"name": "teleport-portal",
		"parameter_count": 9,
		"parameter_descriptions": [
			"Destination field",
			"Destination room",
			"Destination screen",
			"Destination screen X",
			"Destination screen Y",
			"Size of warp gTile dX",
			"Size of warp gTile dY",
			"Enter animation",
			"Exit animation"
		],
		"notes": "\tThese do not activate when you teleport (or use a field transition gate) to enter their area of effect.\n    Animations: 1=oval move left 3=oval move right 4=circle default=hardlock game\n\t\n\n",
		"write_flag_notes": ""
	},
	"0x98": {
		"name": "teleport-doo",
		"parameter_count": 6,
		"parameter_descriptions": [
			"Interaction type: 0 = press up. 1 = press down.",
			"Destination field",
			"Destination room",
			"Destination screen",
			"Destination screen X",
			"Destination screen Y"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0x99": {
		"name": "effect-dust",
		"parameter_count": 8,
		"parameter_descriptions": [
			"Type 0-Cloud 1-Cloud + particulate",
			"CloudLayer",
			"dX",
			"dY",
			"ParticulateLayer",
			"ParticulateR",
			"ParticulateG",
			"ParticulateB"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0x9A": {
		"name": "Falling Room",
		"parameter_count": 25,
		"parameter_descriptions": [
			"Layer",
			"Destroy Effect (only 0?)",
			"HurtBox + Collision Detection dX",
			"HurtBox + Collision Detection dY ",
			"ActivationDelay",
			"dV",
			"Vf",
			"",
			"FramesRotation",
			"DegreesRotation",
			"",
			"ExitEffect",
			"Graphic",
			"Room Number",
			"graphic U",
			"graphic V",
			"graphic dU",
			"graphic dV",
			"Start Sound Select",
			"Collide Sound Select",
			"HP or %",
			"Damage",
			"UseTileFill-Stationary",
			"UseTileFill-Motion",
			"DamageType: 0:hitbox8 1:hitbox5"
		],
		"notes": "            (No hurtbox or collision on top 20 px)\n        Default=none\n        1=fade - no rotation support\n        2=fade\n        3=LargeBreak+dust\n        0=mapXX_1.png\n        1=evegXX.png\n        2=00prof.png\n        3=02comenemy.png\n        4=00item.png\n        5=01menu.png\n        6=00item.png\n        7=01effect.png\n        8=msd room\n    \n",
		"write_flag_notes": ""
	},
	"0x9B": {
		"name": "effect-sound-once 646",
		"parameter_count": 15,
		"parameter_descriptions": [
			" sound effect    (as the file number)",
			" volume  initial (0-127)",
			" balance initial (0-127, 64 is centered)",
			" pitch   initial (see below)",
			" volume  final   (see below)",
			" balance final",
			" pitch   final",
			" voice priority (higher is better, most game sound effects get 15)",
			" UNUSED????",
			" frames to wait before playing",
			" controller rumble (bool)",
			" ??? rumble strength",
			" volume  slide frames (see below)",
			" balance slide frames (see below)",
			" pitch   slide frames (see below)"
		],
		"notes": "    state 0 sliding\n          1 after playing, tests still pass (no slide)\n          2 after playing, tests stopped passing (no slide)\n         10 delay before playing (initial)0\n            tests pass -> 10 -> play after arg[9] frames -> 1 -> tests stop passing -> 2 -> tests start passing -> back to 10\n            tests pass -> 10 -> play after arg[9] frames with slide -> 0 -> stop\n            sound effect has slide if any parameter's final value is different\n    ARGUMENTS\n    INTERNAL VALUES\n    flt  0  volume  current\n    flt  1  balance current\n    flt  2  pitch   current\n    flt  3  volume  final \n    flt  4  balance final\n    flt  5  pitch   final\n    flt  6  volume  delta\n    flt  7  balance delta\n    flt  8  pitch   delta\n    loc  0 frames waiting to play\n    loc  1 playing sound index\n    \n    If the initial and final values for volume, pitch or balance are not the same, then the sound effect starts out at the initial value, then over the course of the relevant number of slide frames, fades to the final value.\n    For example, if volume initial is 0 and volume final is 120 and volume slide is 60, then every frame for 60 frames, the sound will get 2 louder.\n    \n    Pitch is the sample rate of the sound effect. That is, the higher the pitch, the faster and higher the sound plays. The lower it is, the slower and lower the sound plays. The sample rate is 48 000Hz + pitch * 10Hz. More practically speaking, compare the sound produced by breaking pots in Tower of Ruin to breaking pots in other locations. The pot sound effects in Ruin have a pitch of (approximately) -500.\n    \n",
		"write_flag_notes": ""
	},
	"0x9C": {
		"name": "detection-useitem (use, not held)",
		"parameter_count": 4,
		"parameter_descriptions": [
			"dX",
			"dY",
			"Item",
			"OnlyWhenGrounded"
		],
		"notes": "    // Has a six frame delay :/\n    \n",
		"write_flag_notes": ""
	},
	"0x9D": {
		"name": "misc-maus-skydisk",
		"parameter_count": 6,
		"parameter_descriptions": [
			"screenFlag",
			"screenFlagValueCCW",
			"screenFlagValueCW",
			"SE startMoving",
			"SE finishMoving",
			"SE goodfinishMoving (a flag other than 3 is set)"
		],
		"notes": "    //Update3 is the fail state.\n\n",
		"write_flag_notes": ""
	},
	"0x9E": {
		"name": "language-tablet",
		"parameter_count": 12,
		"parameter_descriptions": [
			"screenplay card",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"dx",
			"dy"
		],
		"notes": "    \n    Card format:\n    <text> <endRecord>\n    <DATA: lang slate> <endRecord>\n    (if slate):\n        <DATA: U V dU dV><endRecord>\n        <DATA: Xpos Ypos>\n        \n    Language: \n        0 English\n        1 La-Mulanese\n        2 Ancient La-Mulanese\n        3 Rosetta Stone\n    Slate:\n        0 No image.\n        1 use slate00.png\n        2 use slate01.png\n    \n    U V Image position in slate.\n    dU dV image size in slate.\n    Xpos Ypos image position in scan.\n        \n",
		"write_flag_notes": ""
	},
	"0x9F": {
		"name": "language-grailpoint (post-reading version) (quicksave)",
		"parameter_count": 9,
		"parameter_descriptions": [
			"screenplay card",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			""
		],
		"notes": "    //arguments have identical usage to 9e, but last 3 are not present\n\n",
		"write_flag_notes": ""
	},
	"0xA0": {
		"name": "language-conversation",
		"parameter_count": 7,
		"parameter_descriptions": [
			"",
			"",
			"",
			"conv-type",
			"block",
			"",
			"Disallow Music Change"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xA1": {
		"name": "misc-sun-sun (as seen in temple of the sun)",
		"parameter_count": 2,
		"parameter_descriptions": [
			"hits to fall",
			"time before fall"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xA2": {
		"name": "misc-com-turret shooter",
		"parameter_count": 14,
		"parameter_descriptions": [],
		"notes": "    0  - facing\n    1  - type (0 frames, 1 hits)\n    2  - number of hits/frames\n    3  - detection width\n    4  - detection height\n    5  - (0-3) Shot Type 0 = forward 1 = spread 2 = roll 3 = homing\n    6  - frames between volley\n    7  - frames per shot\n    8  - shots after the first\n    9  - speed\n    10 - damage\n    11 - eveg x-offset\n    12 - eveg y-offset\n    13 - shot height \n\n",
		"write_flag_notes": ""
	},
	"0xA3": {
		"name": "effect-animation",
		"parameter_count": 23,
		"parameter_descriptions": [
			"layer",
			"",
			"graphic file",
			"mdd select >=72 use internal list from arg22",
			"Entry Effect",
			"Exit Effect",
			"UseDustTrail",
			"Motion Damage",
			"Finished Damage",
			"Flag to set",
			"set flag to 1 when segment id matches",
			"set flag to 2 when segment id matches",
			"set flag to 3 when segment id matches",
			"set flag to 4 when segment id matches",
			"set flag to 5 when segment id matches",
			"set flag to 6 when segment id matches",
			"set flag to 7 when segment id matches",
			"set flag to 8 when segment id matches",
			"(0|1|2) Blend mode",
			"XShift warning: does not affect dust trail",
			"YShift warning: does not affect dust trail",
			"",
			"internal mdd select"
		],
		"notes": "\t\t0=mapxx_1\n\t\t1=evegxx\n\t\t2=00prof\n\t\t3=02comenemy\n\t\t4=00item\n\t\t5=01menu\n\t\t6=00item\n\t\tdefault=01effect\n        1=fade\n        2=fade from black\n        3=fade from white\n        4=fade through black\n        5=fade through white\n        default=appear?\n        0=nothing ever happens\n        1=fade\n        5=fade through black\n        default=vanish\n\t\t\t0: Normal\n\t\t\t1: Add\n\t\t\tDefault: Multiply\n\n",
		"write_flag_notes": "\t\tupdate 0 - act when equal\n\t\tupdate 1 - add value to flag on completion\n\t\tupdate 2 - add value to flag after previous\n\t\tupdate 3 - (if exists, do nothing?)\n"
	},
	"0xA4": {
		"name": "effect-screenshake",
		"parameter_count": 13,
		"parameter_descriptions": [
			"Direction ",
			"",
			"FramesDuration",
			"SE related t/f play sound?",
			"SE select",
			"SE volume   (0-127)",
			"SE balance  (0-127, 64 is centered)",
			"SE pitch    (sound effect is played at 48 000Hz + pitch * 10Hz)",
			"",
			"",
			"MaximumOffset",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			"",
			""
		],
		"notes": "    staring at this kinda gives a headache\n    more later\n    TODO\n        0       - Diagonal\n        1       - Vertical\n        Default - Horizontal\n\n    \n",
		"write_flag_notes": ""
	},
	"0xA5": {
		"name": "misc-spring-drain",
		"parameter_count": 1,
		"parameter_descriptions": [
			"Distance"
		],
		"notes": "    UPDATE 0: Move on equality(?)\n    \n",
		"write_flag_notes": ""
	},
	"0xA6": {
		"name": "misc-illusion-blood",
		"parameter_count": 1,
		"parameter_descriptions": [
			"Damage"
		],
		"notes": "    //Does something with updates?\n    \n",
		"write_flag_notes": ""
	},
	"0xA7": {
		"name": "fairy-keyspot",
		"parameter_count": 3,
		"parameter_descriptions": [
			"Activation Object ",
			"dX",
			"dY"
		],
		"notes": "        0 - Key Fairy\n        1 - Lizard Man\n        (others exist)\n    \n",
		"write_flag_notes": ""
	},
	"0xA8": {
		"name": "misc-sur-boat",
		"parameter_count": 2,
		"parameter_descriptions": [
			"Bouyancy",
			"Max Angle"
		],
		"notes": "    //use high bouyancy and low angles; weird behavior\n\n",
		"write_flag_notes": ""
	},
	"0xA9": {
		"name": "block",
		"parameter_count": 2,
		"parameter_descriptions": [
			"Push Damage",
			"Fall Damage"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0xAA": {
		"name": "blockbutton",
		"parameter_count": 3,
		"parameter_descriptions": [
			"Activate Sound",
			"Block Present when solved (only on room entry)",
			"-1|1|2"
		],
		"notes": "    Update0: Test for active\n    Update1+ after weighted.\n\n",
		"write_flag_notes": ""
	},
	"0xAB": {
		"name": "LASER walls",
		"parameter_count": 2,
		"parameter_descriptions": [
			"% or HP",
			"Damage"
		],
		"notes": "    //Extend upwards until they reach a wall.\n\n",
		"write_flag_notes": ""
	},
	"0xAC": {
		"name": "misc-sun-trolley",
		"parameter_count": 1,
		"parameter_descriptions": [
			"DisablePush"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xAD": {
		"name": "Hotspring",
		"parameter_count": 4,
		"parameter_descriptions": [
			"Width",
			"Height",
			"FramesOfNoHeal",
			"HealAmount"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xAE": {
		"name": "effect-sun-sperm",
		"parameter_count": 1,
		"parameter_descriptions": [
			"Speed"
		],
		"notes": "    //failing tests after creation crashes the game..?\n\n",
		"write_flag_notes": ""
	},
	"0xAF": {
		"name": "effect-com-shawn shorn",
		"parameter_count": 1,
		"parameter_descriptions": [
			"Direction URDL"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0xB0": {
		"name": "block-megaman",
		"parameter_count": 11,
		"parameter_descriptions": [
			"HitTileWidth",
			"HitTileHeight",
			"FramesUsed",
			"FramesNoAnimation",
			"Graphic TODO",
			"U",
			"V",
			"Blend Mode",
			"Damage",
			"Activation Sound Effect",
			"Deactivation Sound Effect"
		],
		"notes": "    Update0 Equality activates.\n    \n",
		"write_flag_notes": ""
	},
	"0xB1": {
		"name": "timer-visibl",
		"parameter_count": 9,
		"parameter_descriptions": [
			"XPosition",
			"YPosition",
			"Minutes",
			"Seconds",
			"F:countdown T:Time Attack countup",
			"Red Seconds",
			"SecondSound",
			"Red Second Sound",
			"probably also a sound?"
		],
		"notes": "    // oddity: initial x is always centered\n    // yet initial y is a distance below final.\n    \n",
		"write_flag_notes": ""
	},
	"0xB2": {
		"name": "misc-endless-infdoors",
		"parameter_count": 5,
		"parameter_descriptions": [
			"Width gtile",
			"Height gtile",
			"horizontal/vertical",
			"pass through count",
			"t/f False behavior unknown"
		],
		"notes": "    // typically performs updates 1-3\n    // update 0 occurs at some unknown time.\n \n",
		"write_flag_notes": ""
	},
	"0xB3": {
		"name": "misc-goddess-scales",
		"parameter_count": 11,
		"parameter_descriptions": [
			"Minimum weights to solve puzzle",
			"Weight0",
			"Weight1",
			"Weight2",
			"Weight3",
			"Weight4",
			"Weight5",
			"Weight6",
			"LemezaWeight",
			"Flag-Left",
			"Flag-Right"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0xB4": {
		"name": "explosion (Gyonin key fairy & fake chest)",
		"parameter_count": 7,
		"parameter_descriptions": [
			"Width & Height",
			"",
			"Frames No Animation",
			"",
			"hp or %",
			"Damage",
			"SE select"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xB5": {
		"name": "item-instant no position Instantly give an item (used for maternity, medecines, surface map)",
		"parameter_count": 4,
		"parameter_descriptions": [
			"Word",
			"Width gtile",
			"Height gtile",
			"SE select"
		],
		"notes": "    //performs all updates on collection\n\n",
		"write_flag_notes": ""
	},
	"0xB6": {
		"name": "Save Functionality",
		"parameter_count": 1,
		"parameter_descriptions": [
			"SE select"
		],
		"notes": "\trange:\n\tx < lemeza + 20 < x + 40\n\ty < lemeza + 24 < y + 40\n\tLemeza must be on the ground\n\tActivates on pressing down.\n\n",
		"write_flag_notes": ""
	},
	"0xB7": {
		"name": "toggle-grail Disable/Enable Holy Grail (no position)",
		"parameter_count": 1,
		"parameter_descriptions": [
			"T/F allow grail"
		],
		"notes": "    // Sets a flag that allows or prevents grail use until changed back.\n    \n",
		"write_flag_notes": ""
	},
	"0xB8": {
		"name": "detection-dance screenplay ref",
		"parameter_count": 3,
		"parameter_descriptions": [
			"screenplay seg",
			"gtile dx",
			"gtile dy"
		],
		"notes": "You get three seconds.\n    Dance moves: 1=jump 2=swing left 3=swing right \n    \n",
		"write_flag_notes": ""
	},
	"0xB9": {
		"name": "roomspawner-move-push",
		"parameter_count": 8,
		"parameter_descriptions": [
			"Texture",
			"U",
			"V",
			"dX",
			"dY",
			"UNUSED",
			"Damage",
			"When landing,"
		],
		"notes": "    Cannot weight block buttons.\n        0 - do nothing\n        1 - disappear & update\n        default - break & update\n\n",
		"write_flag_notes": ""
	},
	"0xBA": {
		"name": "enemy-birth-vessellaser",
		"parameter_count": 3,
		"parameter_descriptions": [
			"Facing L/R",
			"Range gtile",
			"Damage (Reflected is 255)"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xBB": {
		"name": "misc-shrine-pillar-diary",
		"parameter_count": 1,
		"parameter_descriptions": [
			""
		],
		"notes": "    \n",
		"write_flag_notes": "    Update 0 Tested for behavior\n    Update 1 Landed (fail)\n    Update 2 Landed (success)\n    Update 3 Raised (success)\n"
	},
	"0xBC": {
		"name": "SFX-echo (you keep last setting seen, no position)",
		"parameter_count": 6,
		"parameter_descriptions": [
			"t/f update while paused",
			"UNUSED",
			"Wet/dry mix",
			"Density",
			"Room size",
			"UNUSED"
		],
		"notes": "    // applies parameters on first update \n    // and first after tests stop passing then start passing.\n    // Arguments 2-4 are on a 0 to -904 scale. \n    // Rescaled to 0-100 or 1-100 and bounded\n\n",
		"write_flag_notes": ""
	},
	"0xBD": {
		"name": "SFX-controllable",
		"parameter_count": 7,
		"parameter_descriptions": [
			"Index-WRITE 0-29 special:92, 255",
			"SFX select",
			"SFX priority (up to 16 sfx can play at a time. Higher priority means more likely to play.)",
			"SFX volume   (0-127)",
			"SFX balance  (0-127, 64 is centered.)",
			"SFX pitch    (Sound effect is played at 48 000 Hz + pitch * 10 Hz. Negative numbers are ok.)"
		],
		"notes": "    // Pairs with 0xbe\n    \n",
		"write_flag_notes": ""
	},
	"0xBE": {
		"name": "SFX-controller",
		"parameter_count": 5,
		"parameter_descriptions": [
			"Index-READ 0-29",
			"new Priority",
			"new Volume",
			"new Balance",
			"new Pitch"
		],
		"notes": "    // Pairs with 0xbd\n    \n",
		"write_flag_notes": ""
	},
	"0xBF": {
		"name": "GFX-field-name no position",
		"parameter_count": 1,
		"parameter_descriptions": [
			"FieldNumber"
		],
		"notes": "    // Shows the name of the current field.\n    \n",
		"write_flag_notes": ""
	},
	"0xC0": {
		"name": "ankh-mother",
		"parameter_count": 32,
		"parameter_descriptions": [],
		"notes": "    Same as 0x2e ankh, but looks different and requires a keysword to activate.\n    \n",
		"write_flag_notes": ""
	},
	"0xC1": {
		"name": "music-override",
		"parameter_count": 2,
		"parameter_descriptions": [
			"NewOst",
			""
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xC2": {
		"name": "detection-mantra no position",
		"parameter_count": 1,
		"parameter_descriptions": [
			"Mantra Number"
		],
		"notes": "    // destroyed on correct mantra.\n    \n",
		"write_flag_notes": ""
	},
	"0xC3": {
		"name": "detection-snapshots no position",
		"parameter_count": 4,
		"parameter_descriptions": [
			"LocationX",
			"LocationY",
			"TextCard",
			"ItemWord"
		],
		"notes": "    \n",
		"write_flag_notes": ""
	},
	"0xC4": {
		"name": "Field Transition Gate (all directions)",
		"parameter_count": 7,
		"parameter_descriptions": [
			"destfield",
			"destRoom",
			"destscreen",
			"destx",
			"desty",
			"direction UDRL (**not** URDL)",
			"set bitflag, unknown effect. Used in escape."
		],
		"notes": "    // object invisible\n    // one use per screen visit\n    // always performs black screen wipe\n    // does not reset screen\n    // animation continues until lemeza goes off screen\n\n",
		"write_flag_notes": ""
	},
	"0xC5": {
		"name": "timer-visible-escape",
		"parameter_count": 12,
		"parameter_descriptions": [
			"XPosition",
			"YPosition",
			"Minutes",
			"Seconds",
			"0:countdown 1:countup 2:time attack",
			"Red Seconds",
			"Second Sound",
			"Red Second Sound",
			"probably also a sound?",
			"PauseTimerFlag",
			"TimerRunOutFlag",
			"StopTimerFlag"
		],
		"notes": "    //Ends 1 second early.\n    //Only updates the flag in argument 10.\n\n",
		"write_flag_notes": ""
	},
	"0xC6": {
		"name": "Boss Attack (as seen in Hell Temple)",
		"parameter_count": 8,
		"parameter_descriptions": [
			"Boss",
			"Direction",
			"Speed",
			"Damage",
			"",
			"FramesSleep",
			"ShotsperVolley",
			"ShotDuration",
			"Type"
		],
		"notes": "    //Condensed Version:\n    //Full Version:\n        0 Amphisbaena\n            1 - Direction LR -_-;\n            2 - Speed\n            3 - Damage\n            4 - \n            5 - FramesSleep\n            6 - \n            7 - SprayDuration\n        1 Sakit, 2 Ellmac\n            1 - Direction RL \n            2 - Speed\n            3 - Damage\n            4 - \n            5 - FramesSleep\n            6 - Shots/volley\n            7 - ShotDuration\n        3 Bahamut\n            1 - Direction RL\n            2 - Speed\n            3 - Damage\n            4 - \n            5 - FramesSleep\n            6 - \n            7 - SprayDuration\n        4 Viy\n            1 - Direction Degrees\n            2 - \n            3 - Damage\n            4 - \n            5 - FramesSleep\n            6 - \n            7 - LaserDuration\n        5 Palenque, 7 Tiamat\n            1 -\n            2 -\n            3 - Damage\n            4 - \n            5 - FramesSleep\n            6 - ShotsperVolley\n            7 - ShotDuration\n        6 Baphomet\n            1 - \n            2 - \n            3 - Damage\n            4 - \n            5 - FramesSleep\n            6 - \n            7 -  \n            \n",
		"write_flag_notes": ""
	},
	"0xC7": {
		"name": "effect-escape-shake",
		"parameter_count": 2,
		"parameter_descriptions": [],
		"notes": "    0: StopFlag\n    1: StopValue\n    \n    If StopFlag <= 0, then the screenshake does not end.\n    Otherwise, when the [StopFlag] == StopValue, then it stops creating new effects, and the screen vibration ends within a few seconds. \n    \n",
		"write_flag_notes": ""
	},
	"0xC8": {
		"name": "override-mapnames -screenplay reference",
		"parameter_count": 1,
		"parameter_descriptions": [
			"screenplay card"
		],
		"notes": "\n",
		"write_flag_notes": ""
	},
	"0xC9": {
		"name": "Time Attack Ankh",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "    Same as 0x2e Ankh, \n    but doesn't heal and \n    doesn't change music.\n\n",
		"write_flag_notes": ""
	},
	"0xCA": {
		"name": "Time Attack Mother Ankh",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "    Same as 0xc0 MotherAnkh,\n    but doesn't heal and\n    doesn't change music.\n    \n",
		"write_flag_notes": ""
	},
	"0x01": {
		"name": "enemy-guid-myrmecoleon",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x02": {
		"name": "enemy-com-bat",
		"parameter_count": 5,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x03": {
		"name": "enemy-com-skeleton",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x04": {
		"name": "enemy-com-togspawner",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x05": {
		"name": "enemy-com-snouter",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x06": {
		"name": "enemy-com-kodamarat",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x15": {
		"name": "enemy-sur-miniboss-argus",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x16": {
		"name": "enemy-sur-snake",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x17": {
		"name": "enemy-sur-birds",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x18": {
		"name": "enemy-sur-vulture",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x19": {
		"name": "misc-surf-potlady",
		"parameter_count": 3,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x1A": {
		"name": "misc-surf-child",
		"parameter_count": 2,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x1B": {
		"name": "enemy-com-mirrorghosts",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x1C": {
		"name": "enemy-com-maskedman ",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x1D": {
		"name": "enemy-maus-nozuchi (Croissant roll & jump maus)",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x1E": {
		"name": "enemy-maus-fist",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x1F": {
		"name": "enemy-maus-ghosts (no position)",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x20": {
		"name": "enemy-maus-miniboss-ghostlord",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x21": {
		"name": "enemy-guid-redskeleton (guidance)",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x26": {
		"name": "enemy-com-sonic",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x27": {
		"name": "enemy-sun-caitsith (cat ball)",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x28": {
		"name": "enemy-sun-bird",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x29": {
		"name": "enemy-sun-mask",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x2A": {
		"name": "enemy-sun-buer",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x35": {
		"name": "enemy-spring-gyonin",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x36": {
		"name": "enemy-spring-mrgyonin",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x37": {
		"name": "enemy-spring-hippocampus",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x38": {
		"name": "enemy-spring-jelly",
		"parameter_count": 5,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x39": {
		"name": "enemy-spring-leaper",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x3A": {
		"name": "enemy-spring-nuckelavee",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x3B": {
		"name": "enemy-com-exploderock",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x3C": {
		"name": "enemy-com-jumpslime",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x3D": {
		"name": "enemy-inferno-lavarock",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x3E": {
		"name": "enemy-inferno-kakaojuu (walk drop fire)",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x3F": {
		"name": "enemy-inferno-firejet",
		"parameter_count": 5,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x40": {
		"name": "enemy-inferno-pazuzu",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x41": {
		"name": "enemy-com-mandrake",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x42": {
		"name": "enemy-extinct-naga",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x43": {
		"name": "enemy-extinct-garuda",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x44": {
		"name": "enemy-extinct-blob",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x45": {
		"name": "enemy-extinct-centimani",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x46": {
		"name": "enemy-extinct-spriggan",
		"parameter_count": 5,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x47": {
		"name": "enemy-extinct-oxheadandhorseface (both spawn from one instance of object)",
		"parameter_count": 18,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x48": {
		"name": "enemy-endless-bonnacon",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x49": {
		"name": "enemy-endless-flowerfacedsnouter",
		"parameter_count": 11,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x4A": {
		"name": "enemy-endless-monocoli",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x4B": {
		"name": "enemy-endless-jiangshi",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x4C": {
		"name": "enemy-endless-rongxuanwangcorpse",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x4D": {
		"name": "enemy-endless-backbeard",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x4E": {
		"name": "enemy-endless-taisui",
		"parameter_count": 11,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x4F": {
		"name": "enemy-shrine-hundun (teleportation mother jerk)",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x50": {
		"name": "enemy-shrine-pan",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x51": {
		"name": "enemy-shrine-hanuman Shock Monkeys",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x52": {
		"name": "enemy-shrine-enkidu (fire stream)",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x53": {
		"name": "enemy-shrine-marchosias",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x54": {
		"name": "enemy-shrine-beelzebub",
		"parameter_count": 13,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x55": {
		"name": "enemy-twins-witch",
		"parameter_count": 20,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x56": {
		"name": "enemy-twins-siren",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x57": {
		"name": "enemy-twins-xingtian",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x58": {
		"name": "enemy-twins-zaochi (Jump monkey)",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x59": {
		"name": "enemy-twins-lizard (leucrotta)",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x5A": {
		"name": "enemy-twins-peryton",
		"parameter_count": 11,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x5B": {
		"name": "enemy-twins-zu",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x5C": {
		"name": "enemy-illusion-lizard",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x5D": {
		"name": "enemy-illusion-asp (Illusion snake)",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x5E": {
		"name": "enemy-illusion-kui (Illusion hopper)",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x5F": {
		"name": "enemy-illusion-sacrificialmaiden (all)",
		"parameter_count": 2,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x60": {
		"name": "enemy-illusion-ba",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x61": {
		"name": "enemy-illusion-chiyou",
		"parameter_count": 13,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x62": {
		"name": "enemy-com-toujin",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x63": {
		"name": "enemy-grave-dijiang",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x64": {
		"name": "enemy-grave-ice-wizard",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x65": {
		"name": "enemy-grave-cloud",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x66": {
		"name": "enemy-grave-baize icicle shot",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x67": {
		"name": "enemy-grave-kamaitachi",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x68": {
		"name": "enemy-com-anubis small",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x69": {
		"name": "enemy-moon-bug",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x6A": {
		"name": "enemy-moon-troll (moon rock enemy)",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x6B": {
		"name": "enemy-moon-anubis large",
		"parameter_count": 13,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x6C": {
		"name": "enemy-com-ninja (no position)",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x6D": {
		"name": "enemy-goddess-abaoaqu",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x6E": {
		"name": "enemy-goddess-andras (Wolf Riding Demon)",
		"parameter_count": 12,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x6F": {
		"name": "enemy-goddess-medusaheads (no position)",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x70": {
		"name": "enemy-goddess-cyclops",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x71": {
		"name": "enemy-goddess-vimanas",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x73": {
		"name": "enemy-ruin-dog",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x74": {
		"name": "enemy-ruin-salamander",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x75": {
		"name": "enemy-ruin-skyfish (no position)",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x76": {
		"name": "enemy-ruin-lavajet",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x77": {
		"name": "enemy-ruin-thunderbird",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x78": {
		"name": "enemy-ruin-rusalii Note: spawns more than one!",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x79": {
		"name": "enemy-ruin-yaksi",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x7A": {
		"name": "enemy-ruin-dakini",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x7B": {
		"name": "enemy-ruin-nuwa",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x7C": {
		"name": "enemy-com-mudmanspawner",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x7D": {
		"name": "enemy-birth-swordbird",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x7E": {
		"name": "enemy-birth-elephant",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x7F": {
		"name": "enemy-birth-skanda",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x80": {
		"name": "enemy-birth-flipshootbackground",
		"parameter_count": 4,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x81": {
		"name": "enemy-dimen-amon",
		"parameter_count": 10,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x82": {
		"name": "enemy-dimen-devil crown skull",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x83": {
		"name": "enemy-dimen-satan Telephone Demon (satan)",
		"parameter_count": 11,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x84": {
		"name": "enemy-dimen-umudabrutu",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x85": {
		"name": "enemy-dimen-urmahlullu",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x86": {
		"name": "enemy-dimen-ugallu",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x87": {
		"name": "enemy-dimen-kuusarikku",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x88": {
		"name": "enemy-dimen-girtablilu",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x89": {
		"name": "enemy-dimen-kulullu",
		"parameter_count": 8,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x8A": {
		"name": "enemy-dimen-mushnahhu",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x8B": {
		"name": "enemy-dimen-lahamu",
		"parameter_count": 7,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x8C": {
		"name": "enemy-dimen-ushumgallu",
		"parameter_count": 15,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x8D": {
		"name": "enemy-dimen-ushum",
		"parameter_count": 6,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x8E": {
		"name": "enemy-dimen-mushussu",
		"parameter_count": 9,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x8F": {
		"name": "enemy-hell-miniboss",
		"parameter_count": 11,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0x90": {
		"name": "enemy-hell-theboss",
		"parameter_count": 15,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	},
	"0xCB": {
		"name": "shift-enemy-sprites <- weird",
		"parameter_count": 1,
		"parameter_descriptions": [],
		"notes": "No details available",
		"write_flag_notes": ""
	}
}
