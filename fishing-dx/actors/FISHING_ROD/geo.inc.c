#include "src/game/envfx_snow.h"

const GeoLayout FISHING_ROD_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, FISHING_ROD_FISHING_ROD_mesh_layer_1),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, FISHING_ROD_final_revert_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
