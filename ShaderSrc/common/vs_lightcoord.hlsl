#if ((FLAG1_MATERIAL_SHADOW) && (!FLAG2_REFLECTION_CASTER))
	#if (FLAG2_CSM)
	result.lightcoord[0] = mul( position, mtxLightViewProj[0]);
	result.lightcoord[1] = mul( position, mtxLightViewProj[1]);
	result.lightcoord[2] = mul( position, mtxLightViewProj[2]);
	#else
	result.lightcoord = mul( position, mtxLightViewProj[0]);
	#endif
#endif
