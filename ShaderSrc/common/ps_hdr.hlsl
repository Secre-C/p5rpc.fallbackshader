#if (FLAG0_HDR) && (!FLAG0_FLOAT_RENDER_TARGET)	&& (!FLAG2_REFLECTION_CASTER)	//	#if (FLAG0_HDR_PS3)
	#if (FLAG0_BLOOM)
		float tmp,scl;
		tmp = max( max( result.color.r, result.color.g), max( result.color.b, 0.25));
		scl = 1.0 / tmp;
		result.color = float4(result.color.rgb * scl, 0.2475 * scl);
	#else
		result.color.a = 1.0;
	#endif
#elif (FLAG0_HDR) && (FLAG0_FLOAT_RENDER_TARGET) && (!FLAG2_REFLECTION_CASTER) // 16/12/13
	// 小数バッファとマテリアルのブルームフラグに対応
	#if (FLAG0_BLOOM)
		result.color.a = 0.0f;// 本当は0.998f等にしたいが精度が2bitしかないので
	#else
		result.color.a = 1.0f;
	#endif
#elif (FLAG0_OPAQUE_ALPHA1)
	result.color.a = 1.0;
#endif
