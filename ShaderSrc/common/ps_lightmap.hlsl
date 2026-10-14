	#if (FLAG1_TEXTURE9)
		//lightAmbient += lmapAmbient;
		#if (FLAG2_LIGHTMAP_MODULATE)
			lightDiffuse = lerp( light0Diffuse.rgb, lightDiffuse, lightCol.r);
		#elif (FLAG1_LIGHTMAP_MODULATE2)
			lightDiffuse *= 1.f - lightCol.r;
		#else
			lightDiffuse += lightCol.rgb;
		#endif
	#endif
