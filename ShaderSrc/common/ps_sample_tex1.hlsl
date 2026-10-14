#if (FLAG1_TEXTURE1)
	#if (CHANNEL_TEX1 == 0)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord0.xy );
	#elif (CHANNEL_TEX1 == 1)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord1.xy );
	#elif (CHANNEL_TEX1 == 2)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord2.xy );
	#endif
#else
	result.color = float4(1,1,1,1);
#endif
