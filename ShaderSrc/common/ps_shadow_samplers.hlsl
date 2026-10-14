SamplerComparisonState	shadowSampler : register(s10);
	#if (FLAG2_CSM)
		Texture2D		shadowTexture0 : register(t10);
		Texture2D		shadowTexture1 : register(t11);	
		Texture2D		shadowTexture2 : register(t12);	
	#else
		Texture2D		shadowTexture    : register(t10);
	#endif
