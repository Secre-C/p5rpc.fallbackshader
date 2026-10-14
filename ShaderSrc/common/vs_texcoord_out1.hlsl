#if (FLAG0_TEXCOORD1OUT)
	#if (IN_TEXCOORD1 == 0)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV1Transform).xy;
		#else
			result.texcoord1 = vertex.texcoord0;
		#endif
	#elif (IN_TEXCOORD1 == 1)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV1Transform).xy;
		#else
			result.texcoord1 = vertex.texcoord1;
		#endif
	#elif (IN_TEXCOORD1 == 2)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV1Transform).xy;
		#else
			result.texcoord1 = vertex.texcoord2;
		#endif
	#endif
#endif
