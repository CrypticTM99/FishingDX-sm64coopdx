const GeoLayout metalpole_geo[] = {
	GEO_CULLING_RADIUS(1000),
	GEO_OPEN_NODE(),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, polemetal_metalpole_mesh_layer_1),
		GEO_DISPLAY_LIST(LAYER_OPAQUE, polemetal_final_revert_mesh_layer_1),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
