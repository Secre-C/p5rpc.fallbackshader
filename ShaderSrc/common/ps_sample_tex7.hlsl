	#if (CHANNEL_TEX7 == 0)
		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord0).rgb;
	#elif (CHANNEL_TEX7 == 1)
		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord1).rgb;
	#elif (CHANNEL_TEX7 == 2)
		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord2).rgb;
	#endif
