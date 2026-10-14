	#if (FLAG0_OUTLINE)
		float3 outlineN;
		#if (FLAG1_TEXTURE2)
			outlineN = normalize(fragment.normal.xyz);
		#else
			outlineN = N;
		#endif
		#if (FLAG1_MATERIAL_HEIGHTFOG)
			result.outline.rgb = 0.5f * outlineN * (1.f - hfAlpha) + 0.5f;
		#else
			result.outline.rgb = 0.5f * outlineN + 0.5f;
		#endif
		result.outline.a = matOutlineIndex;
	#endif
