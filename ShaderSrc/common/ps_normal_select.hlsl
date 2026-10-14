	#if (FLAG1_TEXTURE2)
		N = normalVec;
	#else
		N = normalize(fragment.normal.xyz);
	#endif
