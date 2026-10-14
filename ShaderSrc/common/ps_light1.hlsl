	#if (FLAG0_LIGHT1_DIRECTION)
		L = normalize(fragment.light1Vec.xyz);
		D = saturate( dot( L, N) );
		lightAmbient += light1Ambient.rgb;
		lightDiffuse += light1Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light1Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#elif (FLAG0_LIGHT1_POINT)
		float K;
		float A;
		K = length(fragment.light1Vec.xyz);
		A = 1.f / (light1Attenuation.x + light1Attenuation.y * K + light1Attenuation.z * K * K);
		L = normalize(fragment.light1Vec.xyz);
		D = saturate( dot( L, N) ) * D;
		lightAmbient += light1Ambient.rgb * A;
		lightDiffuse += light1Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light1Specular.rgb * pow( max( dot( H, N), 0.f), P) * A;
		#endif
	#elif (FLAG0_LIGHT1_SPOT)
		L = normalize(fragment.light1Vec.xyz);
		D = saturate( dot( L, N) );
		lightAmbient += light1Ambient.rgb;
		lightDiffuse += light1Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light1Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#endif
