	#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
		#if (FLAG0_LIGHT0_DIRECTION)
		result.light0Vec = light0Vec;
			#if (FLAG1_TEXTURE2)
			result.light0TangentDir = float4( mul( light0Vec.xyz, transpose(tangentMtx) ) , 1.f);
			#endif
		#else
		result.light0Vec = light0Vec - position;
			#if (FLAG1_TEXTURE2)
			result.light0TangentDir = float4( mul( normalize(result.light0Vec.xyz), transpose(tangentMtx) ) , 1.f);
			#endif
		#endif
	#endif
