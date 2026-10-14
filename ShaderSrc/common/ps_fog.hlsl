#if (FLAG1_MATERIAL_FOG)
	#if (FLAG2_MATERIAL_MODULATE_FOG)
		float fs = (1.f - fragment.misc.x) * fogColor.a * (1.0f - fogDisable);
		result.color.rgb *= (1.f - fs) + fogColor.rgb * fs;
	#else
		float fs = (1.f - fragment.misc.x) * fogColor.a * (1.0f - fogDisable);
		result.color.rgb = lerp( result.color.rgb, fogColor.rgb, fs );
	#endif
#endif
