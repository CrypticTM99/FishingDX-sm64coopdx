const GeoLayout pole_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, pole_pole_mesh_layer_1),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, pole_final_revert_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
