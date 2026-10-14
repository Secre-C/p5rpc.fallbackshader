#if (FLAG1_MATERIAL_HEIGHTFOG)
	float hfAlpha = saturate(fragment.normal.w * heightFogColor.a * (1.0f - fogDisable));
#endif
