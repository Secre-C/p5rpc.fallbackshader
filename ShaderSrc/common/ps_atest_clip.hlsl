	#if (FLAG2_ATEST_NEVER)
		clip(-1);
	#elif (FLAG2_ATEST_LESS_LEQUAL)
		clip( atestRef - result.color.a );
	#elif (FLAG2_ATEST_EQUAL)
		clip( -(result.color.a != atestRef) );
	#elif (FLAG2_ATEST_GREATER_GEQUAL)
		clip( result.color.a - atestRef);
	#elif (FLAG2_ATEST_NOTEQUAL)
		clip( -(result.color.a == atestRef) );
	#endif
