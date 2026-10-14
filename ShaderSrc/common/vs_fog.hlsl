#if (FLAG1_MATERIAL_FOG)
	float4 view = mul( position, mtxView);

#if 1 // 2015/09/04 niida
	float z      = -view.z;
	float param0 = fog.y;
	float param1 = fog.z;
	float fraction;

	if( fog.w == 0.f )
	{
		// linear
		fraction = z * param1 + ( param0 - 1.0f );
	}else
	if( fog.w == 1.f )
	{
		// exponential
		float dist = 11.084f * ( param1 * z + param0 - 1.5f );
		fraction   = exp( dist );
	}else{
		// exponential2
		float dist = 4.709f * ( param1 * z + param0 - 1.5f );
		fraction   = exp( -( dist * dist ) );
	}

	result.misc.x   = saturate( fraction );
	result.misc.yzw = 0;
#else
	result.misc   = 0;
	result.misc.x = clamp( (fog.y + view.z) * fog.z, 0.0f, 1.0f);
#endif

#endif

#if (FLAG1_MATERIAL_HEIGHTFOG)
	result.normal.w = heightFog.x + position.y * heightFog.y;
#endif
