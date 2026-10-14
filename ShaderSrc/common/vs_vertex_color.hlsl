#if (FLAG1_MATERIAL_VERTEXCOLOR)
	#if (FLAG0_CONSTANTCOLOR)
		result.color = vertex.color * constantColor;
	#else
		result.color = vertex.color;
	#endif
#else
	#if (FLAG0_CONSTANTCOLOR)
		result.color = constantColor;
	#endif
#endif
