	#if (FLAG0_LIGHT2_DIRECTION || FLAG0_LIGHT2_POINT || FLAG0_LIGHT2_SPOT)
		#if (FLAG0_LIGHT2_DIRECTION)
		result.light2Vec = light2Vec;
		#else
		result.light2Vec = light2Vec - position;
		#endif
	#endif
