const GeoLayout masterpole_geo[] = {
	GEO_CULLING_RADIUS(1000),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, masterpole_masterpole_mesh_layer_1),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, masterpole_final_revert_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
