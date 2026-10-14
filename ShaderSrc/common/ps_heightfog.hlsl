#if (FLAG1_MATERIAL_HEIGHTFOG)
	#if (FLAG2_MATERIAL_MODULATE_FOG)
		result.color.rgb *= (1.f - hfAlpha) + heightFogColor.rgb * hfAlpha;
	#else
		result.color.rgb  = lerp( result.color.rgb, heightFogColor.rgb, hfAlpha);
	#endif
#endif
