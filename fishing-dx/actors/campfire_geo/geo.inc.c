const GeoLayout campfire_geo[] = {
	GEO_CULLING_RADIUS(4000),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, campfire_campfire_mesh_layer_1),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, campfire_final_revert_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
