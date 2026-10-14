#if (FLAG1_TEXTURE7)
	result.color.rgb *= darkCol;
#endif

#if (FLAG1_TEXTURE8)
	result.color.rgb *= detailCol;
#endif

#if (FLAG1_TEXTURE6)
	result.color.rgb += glowCol;
#endif
