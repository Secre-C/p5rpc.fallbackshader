	#if (CHANNEL_TEX9 == 0)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord0);
	#elif (CHANNEL_TEX9 == 1)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord1);
	#elif (CHANNEL_TEX9 == 2)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord2);
	#endif
