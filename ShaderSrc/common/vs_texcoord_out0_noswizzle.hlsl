#if (FLAG0_TEXCOORD0OUT)
	#if (IN_TEXCOORD0 == 0)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV0Transform);
		#else
			result.texcoord0 = vertex.texcoord0;
		#endif
	#elif (IN_TEXCOORD0 == 1)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV0Transform);
		#else
			result.texcoord0 = vertex.texcoord1;
		#endif
	#elif (IN_TEXCOORD0 == 2)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV0Transform);
		#else
			result.texcoord0 = vertex.texcoord2;
		#endif
	#endif
#endif
