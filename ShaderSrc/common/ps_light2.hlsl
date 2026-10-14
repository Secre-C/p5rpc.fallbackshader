	#if (FLAG0_LIGHT2_DIRECTION)
		L = normalize(fragment.light2Vec.xyz);
		D = saturate( dot( L, N) );
		lightAmbient += light2Ambient.rgb;
		lightDiffuse += light2Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light2Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#elif (FLAG0_LIGHT2_POINT)
		float K;
		float A;
		K = length(fragment.light2Vec.xyz);
		A = 1.f / (light2Attenuation.x + light2Attenuation.y * K + light2Attenuation.z * K * K);
		L = normalize(fragment.light2Vec.xyz);
		D = saturate( dot( L, N) ) * D;
		lightAmbient += light2Ambient.rgb * A;
		lightDiffuse += light2Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light2Specular.rgb * pow( max( dot( H, N), 0.f), P) * A;
		#endif
	#elif (FLAG0_LIGHT2_SPOT)
		L = normalize(fragment.light2Vec.xyz);
		D = saturate( dot( L, N) );
		lightAmbient += light2Ambient.rgb;
		lightDiffuse += light2Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light2Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#endif
