class_name Palette
extends RefCounted
# owns: the closed 44-colour palette as engine-readable constants, matching DESIGN.md section 2
# does not own: which colours a given chapter or room is allowed to use (also DESIGN.md section 2)

const INK: Color = Color("#1a1114")
const BARK: Color = Color("#2e1f1c")
const WALNUT: Color = Color("#4a3229")
const TIMBER: Color = Color("#6b4a35")
const PINE: Color = Color("#8f6844")
const SAWN: Color = Color("#b58a5c")
const PAPER_MID: Color = Color("#d4b184")
const PAPER_LIGHT: Color = Color("#ecd6b0")

const NIGHT: Color = Color("#0d0f16")
const SLATE_DARK: Color = Color("#1c222e")
const SLATE: Color = Color("#2f3a4a")
const STONE: Color = Color("#465666")
const CONCRETE: Color = Color("#647486")
const ASH: Color = Color("#8996a5")
const PALE_STEEL: Color = Color("#b0bcc7")
const FROST: Color = Color("#dce3e8")

const EMBER_DARK: Color = Color("#5c1f14")
const EMBER: Color = Color("#8a3218")
const RUST_ORANGE: Color = Color("#bf4f1c")
const DUSK: Color = Color("#e07a2c")
const LAMPLIGHT: Color = Color("#f2a34a")
const HEARTH: Color = Color("#f9c877")

const POND_DEEP: Color = Color("#101d33")
const POND: Color = Color("#1b3557")
const WATER: Color = Color("#28517d")
const COLD_BLUE: Color = Color("#3a75a8")
const SKY: Color = Color("#5fa0cc")
const ICE: Color = Color("#96c9e3")

const FOREST_DEEP: Color = Color("#101f16")
const FOREST: Color = Color("#1e3a22")
const MOSS: Color = Color("#33552e")
const LEAF: Color = Color("#4d7a3a")
const GRASS: Color = Color("#71a04c")
const NEW_GROWTH: Color = Color("#a3c368")

const SAWDUST_DARK: Color = Color("#6b5615")
const SAWDUST: Color = Color("#9c7c1e")
const BRASS: Color = Color("#c9a52c")
const SHAVING: Color = Color("#e8ca55")

const DEEP_RED: Color = Color("#7a1230")
const CALICO_RED: Color = Color("#c2334f")
const MEMORY_PURPLE: Color = Color("#4a2d5c")
const DOCUMENT: Color = Color("#d9d2c0")

const GREY_GREEN: Color = Color("#54655a")
const CLINIC_WHITE: Color = Color("#f0ece0")

## every colour in the closed set, for a fast "is this on-palette" check when validating art
static func all_colors() -> PackedColorArray:
	return PackedColorArray([
		INK, BARK, WALNUT, TIMBER, PINE, SAWN, PAPER_MID, PAPER_LIGHT,
		NIGHT, SLATE_DARK, SLATE, STONE, CONCRETE, ASH, PALE_STEEL, FROST,
		EMBER_DARK, EMBER, RUST_ORANGE, DUSK, LAMPLIGHT, HEARTH,
		POND_DEEP, POND, WATER, COLD_BLUE, SKY, ICE,
		FOREST_DEEP, FOREST, MOSS, LEAF, GRASS, NEW_GROWTH,
		SAWDUST_DARK, SAWDUST, BRASS, SHAVING,
		DEEP_RED, CALICO_RED, MEMORY_PURPLE, DOCUMENT,
		GREY_GREEN, CLINIC_WHITE,
	])

static func is_on_palette(color: Color) -> bool:
	for palette_color: Color in all_colors():
		if palette_color.is_equal_approx(color):
			return true
	return false
