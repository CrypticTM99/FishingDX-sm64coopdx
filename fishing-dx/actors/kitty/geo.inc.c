#include "src/game/envfx_snow.h"

const GeoLayout kitty_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, kitty_kitty_mesh_layer_1),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, kitty_final_revert_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
