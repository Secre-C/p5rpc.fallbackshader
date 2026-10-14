	#if (FLAG0_LIGHT1_DIRECTION || FLAG0_LIGHT1_POINT || FLAG0_LIGHT1_SPOT)
		#if (FLAG0_LIGHT1_DIRECTION)
		result.light1Vec = light1Vec;
		#else
		result.light1Vec = light1Vec - position;
		#endif
	#endif
