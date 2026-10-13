
/*---------------------------------------------------------------------------*/
struct gfd3DVpOut
{
	float4 position	 : S_POSITION;

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_MATERIAL_HEIGHTFOG)
	#if (FLAG1_MATERIAL_HEIGHTFOG)
	float4 normal : NORMAL;
	#else
	float3 normal : NORMAL;
	#endif
#endif

#if (FLAG1_MATERIAL_LIGHT)

	#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
	float4 light0Vec : TEXCOORD1;
		#if (FLAG1_TEXTURE2)
		float4 light0TangentDir : TEXCOORD4;
		#endif
	#endif

	#if (FLAG0_LIGHT1_DIRECTION || FLAG0_LIGHT1_POINT || FLAG0_LIGHT1_SPOT)
	float4 light1Vec : TEXCOORD2;
	#endif

	#if (FLAG0_LIGHT2_DIRECTION || FLAG0_LIGHT2_POINT || FLAG0_LIGHT2_SPOT)
	float4 light2Vec : TEXCOORD3;
	#endif

#endif

#if (FLAG1_TEXTURE2)
	float3 viewTangentDir : TANGENT;
#else
	float3 viewDir : BINORMAL;
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR)
	float4 color : COLOR0;
#endif

#if (FLAG0_TEXCOORD0OUT)
	float2 texcoord0 : TEXCOORD0;
#endif

#if (FLAG0_TEXCOORD1OUT)
	float2 texcoord1 : TEXCOORD7;
#endif

#if (FLAG0_TEXCOORD2OUT)
	float2 texcoord2 : TEXCOORD8;
#endif

#if (FLAG1_MATERIAL_FOG)
	float4 misc : COLOR1; // COLOR1.x = fog
#endif

	float4	worldPos : TEXCOORD10;
	float3	eyePos   : TEXCOORD11;
};

/*---------------------------------------------------------------------------*/
struct gfdFpOut
{
	float4	color	: S_TARGET_OUTPUT0;
//	float	depth	: S_DEPTH_OUTPUT;
#if (FLAG0_OUTLINE)
	float4	outline	: S_TARGET_OUTPUT1;
#endif
};

/*---------------------------------------------------------------------------*/

ConstantBuffer GFD_PSCONST_SYSTEM : register(b0)
{
	float4	clearColor;		// 画面クリアカラー
	float2	resolution;		// 画面解像度
	float2	resolutionRev;	// 解像度逆数
}

ConstantBuffer GFD_PSCONST_MATERIAL : register(b1)
{
	float4	matAmbient;
	float4	matDiffuse;
	float4	matSpecular;
	float4	matEmissive;
	float	matReflectivity;
	float	matOutlineIndex;
	float	shadowDisable;
	float	fogDisable;
}

ConstantBuffer GFD_PSCONST_LIGHT0_PS : register(b2)
{
	float4	light0Ambient;
	float4	light0Diffuse;
	float4	light0Specular;
	float3	light0Attenuation;
	float2	light0Spot;
	float2	_reserved_b2;
}

ConstantBuffer GFD_PSCONST_LIGHT1_PS : register(b3)
{
	float4	light1Ambient;
	float4	light1Diffuse;
	float4	light1Specular;
	float3	light1Attenuation;
	float2	light1Spot;
	float2	_reserved_b3;
}

ConstantBuffer GFD_PSCONST_LIGHT2_PS : register(b4)
{
	float4	light2Ambient;
	float4	light2Diffuse;
	float4	light2Specular;
	float3	light2Attenuation;
	float2	light2Spot;
	float2	_reserved_b4;
}

ConstantBuffer GFD_PSCONST_ENV_COLORS : register(b5)
{
	float4	fogColor;
	float4	heightFogColor;
	float3	lmapAmbient;
	float	atestRef;
}

#if (FLAG2_PCF)
ConstantBuffer GFD_PSCONST_SHADOW : register(b6)
{
	float	dimmerDif;
	float	dimmerAmb;
	float	depthBias;
	float	shiftPCF;
	float4	csmDebugColorNear;
	float4	csmDebugColorFar;
}
#endif

#if (FLAG2_VSM)
ConstantBuffer GFD_PSCONST_SHADOW : register(b6)
{
	float4	vsm;
}
#endif

ConstantBuffer GFD_PSCONST_WATER : register(b8)
{
	float4x4	waterViewProj;
	float3		waterWaveLength;
	float		waterTime;
	float3		waterAmplitude;
	float		reflectAlpha;
	float3		waterSpeed;
//	float		refractAlpha;
	float		refractRatio;
}

/*--------------------------------------------------
 * テクスチャ定義
--------------------------------------------------*/
#if (FLAG1_TEXTURE1)
Texture2D 		diffuseTexture : register(t0);
SamplerState	diffuseSampler : register(s0);
#endif

#if (FLAG1_TEXTURE2)
Texture2D		normalTexture : register(t1);
SamplerState	normalSampler : register(s1);
#endif

#if (FLAG1_TEXTURE3)
Texture2D		specularTexture : register(t2);
SamplerState	specularSampler : register(s2);
#endif

#if (FLAG1_TEXTURE4 && FLAG1_MATERIAL_REFLECTION)
	#if (FLAG2_FAKE_REFLECTION)
		Texture2D   reflectionTexture : register(t3);
	#else
		TextureCube reflectionTexture : register(t3);
	#endif
SamplerState	reflectionSampler : register(s3);
#endif

#if (FLAG1_TEXTURE5)
Texture2D		multipleTexture : register(t4);
SamplerState	multipleSampler	: register(s4);
#endif

#if (FLAG1_TEXTURE6)
Texture2D		glowTexture : register(t5);
SamplerState	glowSampler	: register(s5);
#endif

#if (FLAG1_TEXTURE7)
Texture2D 		darkTexture : register(t6);
SamplerState	darkSampler	: register(s6);
#endif

#if (FLAG1_TEXTURE8)
Texture2D		detailTexture : register(t7);
SamplerState	detailSampler : register(s7);
#endif

#if (FLAG1_TEXTURE9)
Texture2D		lightTexture : register(t8);
SamplerState	lightSampler : register(s8);
#endif

#if (FLAG2_WATER_REFLECTION)
Texture2D		waterReflectTexture : register(t15);
SamplerState	waterReflectSampler : register(s15);
#endif

#if (FLAG0_DEFERRED)
Texture2D		lbufferTexture : register(t14);
SamplerState	lbufferSampler : register(s14);
#endif


/*---------------------------------------------------------------------------*/

gfdFpOut main( gfd3DVpOut fragment )
{
	gfdFpOut result;
	float3   waterNormal;
	float3   waterDir;

#if (FLAG1_TEXTURE1)
	#if (CHANNEL_TEX1 == 0)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord0.xy );
	#elif (CHANNEL_TEX1 == 1)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord1.xy );
	#elif (CHANNEL_TEX1 == 2)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord2.xy );
	#endif
#else
	result.color = float4(1,1,1,1);
#endif

#if (FLAG1_MATERIAL_AMBDIFF)
	result.color.a *= matDiffuse.a;
#endif

#if (!(FLAG1_MATERIAL_VERTEXCOLOR) && !(FLAG0_CONSTANTCOLOR))
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
#endif

#if (FLAG1_TEXTURE5)
	#if (CHANNEL_TEX5 == 0)
		float4 multipleCol = multipleTexture.Sample(multipleSampler,fragment.texcoord0);
	#elif (CHANNEL_TEX5 == 1)
		float4 multipleCol = multipleTexture.Sample(multipleSampler,fragment.texcoord1);
	#elif (CHANNEL_TEX5 == 2)
		float4 multipleCol = multipleTexture.Sample(multipleSampler,fragment.texcoord2);
	#endif

	#if (FLAG2_MATERIAL_MULTIPLE_SEMI)
		result.color.rgb  = lerp( result.color.rgb, multipleCol.rgb, multipleCol.a * matAmbient.a);
	#elif (FLAG2_MATERIAL_MULTIPLE_ADD)
		result.color.rgb += multipleCol.rgb * multipleCol.a * matAmbient.a;
	#elif (FLAG2_MATERIAL_MULTIPLE_SUB)
		result.color.rgb -= multipleCol.rgb * multipleCol.a * matAmbient.a;
	#elif (FLAG3_MATERIAL_MULTIPLE_MODULATE)
		result.color.rgb *= multipleCol.rgb * multipleCol.a * matAmbient.a;
	#endif
#endif

#if (!FLAG2_SPECULAR_NORMALMAPALPHA)
	#if (FLAG1_TEXTURE3)
		#if (CHANNEL_TEX3 == 0)
			float3 glossCol = specularTexture.Sample(specularSampler,fragment.texcoord0).rgb;
		#elif (CHANNEL_TEX3 == 1)
			float3 glossCol = specularTexture.Sample(specularSampler,fragment.texcoord1).rgb;
		#elif (CHANNEL_TEX3 == 2)
			float3 glossCol = specularTexture.Sample(specularSampler,fragment.texcoord2).rgb;
		#endif
	#endif
#else
	float glossCol;
#endif

#if (FLAG1_TEXTURE6)
	#if (CHANNEL_TEX6 == 0)
		float3 glowCol = glowTexture.Sample(glowSampler,fragment.texcoord0).rgb;
	#elif (CHANNEL_TEX6 == 1)
		float3 glowCol = glowTexture.Sample(glowSampler,fragment.texcoord1).rgb;
	#elif (CHANNEL_TEX6 == 2)
		float3 glowCol = glowTexture.Sample(glowSampler,fragment.texcoord2).rgb;
	#endif
#endif

#if (FLAG1_TEXTURE7)
	#if (CHANNEL_TEX7 == 0)
		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord0).rgb;
	#elif (CHANNEL_TEX7 == 1)
		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord1).rgb;
	#elif (CHANNEL_TEX7 == 2)
		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord2).rgb;
	#endif
#endif

#if (FLAG1_TEXTURE8)
	#if (CHANNEL_TEX8 == 0)
		float3 detailCol = detailTexture.Sample(detailSampler,fragment.texcoord0).rgb;
	#elif (CHANNEL_TEX8 == 1)
		float3 detailCol = detailTexture.Sample(detailSampler,fragment.texcoord1).rgb;
	#elif (CHANNEL_TEX8 == 2)
		float3 detailCol = detailTexture.Sample(detailSampler,fragment.texcoord2).rgb;
	#endif
	detailCol *= 2.f;
#endif

#if (FLAG1_TEXTURE9)
	#if (CHANNEL_TEX9 == 0)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord0);
	#elif (CHANNEL_TEX9 == 1)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord1);
	#elif (CHANNEL_TEX9 == 2)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord2);
	#endif
#endif

#if (FLAG1_TEXTURE2)
	float4 normalCol;
	float3 normalVec;
	#if (CHANNEL_TEX2 == 0)
		normalCol = normalTexture.Sample(normalSampler,fragment.texcoord0);
	#elif (CHANNEL_TEX2 == 1)
		normalCol = normalTexture.Sample(normalSampler,fragment.texcoord1);
	#elif (CHANNEL_TEX2 == 2)
		normalCol = normalTexture.Sample(normalSampler,fragment.texcoord2);
	#endif
	normalVec = normalize( 2.f * normalCol.xyz - 1.f);
	#if (FLAG2_SPECULAR_NORMALMAPALPHA)
		glossCol = normalCol.a;
	#endif
#endif


	float3 waterViewDir = normalize( fragment.eyePos - fragment.worldPos.xyz );

#if (FLAG1_TEXTURE2)
	waterDir    = normalVec;
	waterNormal = normalVec;
#else
	const float3 frequency = 2.0f * 3.14159265358979323846f / waterWaveLength;
	const float3 phase     = waterSpeed * frequency;
	const float2 planePos  = float2( fragment.worldPos.x, fragment.worldPos.z );
	float2 waveDir1 = float2( 1.000,  0.000 );
	float2 waveDir2 = float2( 0.970,  0.242 );
	float2 waveDir3 = float2( 0.919, -0.394 );
	float3 Length = float3( dot( waveDir1, planePos ),
							dot( waveDir2, planePos ),
							dot( waveDir3, planePos )
							);
	float3 waveDirX = float3( waveDir1.x, waveDir2.x, waveDir3.x );
	float3 waveDirY = float3( waveDir1.y, waveDir2.y, waveDir3.y );
	float3 waveCos = frequency * waterAmplitude * cos( frequency * Length - phase * waterTime );
	float dX = dot( waveDirX, waveCos );
	float dY = dot( waveDirY, waveCos );
	waterDir    = float3( -1.f * dX, 1.f, -1.f * dY );
	waterNormal = normalize( waterDir );
#endif

#if (FLAG2_WATER_REFLECTION)
	float4 reflectDir;
	float4 windowPos;
	float2 refcoord;

	reflectDir        = float4( reflect( -waterViewDir, waterDir ), 1.0f );
	reflectDir.xyz   += fragment.worldPos.xyz;
	windowPos         = mul( reflectDir, waterViewProj );
	refcoord          = 0.50f * ( windowPos.xy / windowPos.w ) + 0.50f;
	refcoord.y        = 1.0f - refcoord.y;
	result.color.rgb *= lerp( result.color.rgb, waterReflectTexture.Sample( waterReflectSampler, refcoord ).rgb, reflectAlpha );
#endif

#if (FLAG1_MATERIAL_HEIGHTFOG)
	float hfAlpha = saturate(fragment.normal.w * heightFogColor.a * (1.0f - fogDisable));
#endif

#if (FLAG1_MATERIAL_LIGHT)
	float3 L;
	float3 N;
	float  D;
	float3 lightAmbient = float3(0,0,0);
	float3 lightDiffuse = float3(0,0,0);

	#if (FLAG1_TEXTURE2)
		float3 viewDir = normalize(fragment.viewTangentDir);
	#else
		float3 viewDir = normalize(fragment.viewDir);
	#endif

	#if (FLAG1_TEXTURE2)
		N = normalVec;
	#else
		N = waterNormal;
	#endif

	#if (FLAG0_DEFERRED)
		float4 lbuffCol;
		float2 bufcoord;
		bufcoord     = fragment.position.xy * resolutionRev.xy;
		lbuffCol     = lbufferTexture.Sample( lbufferSampler, bufcoord.xy );
		lightAmbient = lbuffCol.rgb;
		lightDiffuse = lbuffCol.rgb;
	#endif

	#if (FLAG1_MATERIAL_SPECULAR)

		#if (!(FLAG0_DEFERRED))
		float3 lightSpecular = float3(0,0,0);
		#else
			#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
				float3 lightSpecular = light0Specular.rgb * lbuffCol.w;
			#else
				float3 lightSpecular = float3( lbuffCol.w );
			#endif
		#endif
		float  P = matSpecular.w;
		float3 H;
	#endif

	#if (FLAG0_OUTLINE)
		float3 outlineN;
		#if (FLAG1_TEXTURE2)
			outlineN = normalize(fragment.normal.xyz);
		#else
			outlineN = N;
		#endif
		#if (FLAG1_MATERIAL_HEIGHTFOG)
			result.outline.rgb = 0.5f * outlineN * (1.f - hfAlpha) + 0.5f;
		#else
			result.outline.rgb = 0.5f * outlineN + 0.5f;
		#endif
		result.outline.a = matOutlineIndex;
	#endif

	#if (FLAG0_LIGHT0_DIRECTION)
		#if (FLAG1_TEXTURE2)
			L = normalize(fragment.light0TangentDir.xyz);
		#else
			L = normalize(fragment.light0Vec.xyz);
		#endif
		D = saturate( dot( L, N) );
		lightAmbient += light0Ambient.rgb;
		lightDiffuse += light0Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light0Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#elif (FLAG0_LIGHT0_POINT)
		float K;
		float A;
		K = length(fragment.light0Vec.xyz);
		A = 1.f / (light0Attenuation.x + light0Attenuation.y * K + light0Attenuation.z * K * K);
		#if (FLAG1_TEXTURE2)
			L = normalize(fragment.light0TangentDir.xyz);
		#else
			L = normalize(fragment.light0Vec.xyz);
		#endif
		D = saturate( dot( L, N) );
		lightAmbient += light0Ambient.rgb * A;
		lightDiffuse += light0Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light0Specular.rgb * pow( max( dot( H, N), 0.f), P) * A;
		#endif
	#elif (FLAG0_LIGHT0_SPOT)
		#if (FLAG1_TEXTURE2)
			L = normalize(fragment.light0TangentDir.xyz);
		#else
			L = normalize(fragment.light0Vec.xyz);
		#endif
		D = saturate( dot( L, N) );
		lightAmbient += light0Ambient.rgb;
		lightDiffuse += light0Diffuse.rgb * D;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light0Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#endif


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

	#if (FLAG1_TEXTURE9)
		//lightAmbient += lmapAmbient;
		#if (FLAG2_LIGHTMAP_MODULATE)
			lightDiffuse = lerp( light0Diffuse.rgb, lightDiffuse, lightCol.r);
		#elif (FLAG1_LIGHTMAP_MODULATE2)
			lightDiffuse *= 1.f - lightCol.r;
		#else
			lightDiffuse += lightCol.rgb;
		#endif
	#endif

	#if (FLAG1_MATERIAL_AMBDIFF)
		#if (FLAG1_MATERIAL_EMISSIVE)
			#if (FLAG2_LIGHTMAP_MODULATE)
				float3 lmAmbient = lerp( lightAmbient, matAmbient.rgb * lightAmbient, lightCol.r);
				result.color.rgb *= matEmissive.rgb + lmAmbient + matDiffuse.rgb * lightDiffuse;
			#else
				result.color.rgb *= matEmissive.rgb + matAmbient.rgb * lightAmbient + matDiffuse.rgb * lightDiffuse;
			#endif
		#else
			#if (FLAG2_LIGHTMAP_MODULATE)
				float3 lmAmbient = lerp( lightAmbient, matAmbient.rgb * lightAmbient, lightCol.r);
				result.color.rgb *= lmAmbient + matDiffuse.rgb * lightDiffuse;
			#else
				result.color.rgb *= matAmbient.rgb * lightAmbient + matDiffuse.rgb * lightDiffuse;
			#endif
		#endif
	#endif

	#if (FLAG1_MATERIAL_SPECULAR)
		#if (FLAG1_TEXTURE3 || FLAG2_SPECULAR_NORMALMAPALPHA)
			result.color.rgb += matSpecular.rgb * lightSpecular * glossCol;
		#else
			result.color.rgb += matSpecular.rgb * lightSpecular;
		#endif
	#endif

#else

	#if (FLAG0_OUTLINE)
		result.outline.rgb = 0;
		result.outline.a   = matOutlineIndex;
	#endif

	#if (FLAG2_SPECULAR_NORMALMAPALPHA)
		glossCol = 0;
	#endif

	#if (FLAG1_MATERIAL_AMBDIFF)
		#if (FLAG1_MATERIAL_EMISSIVE)
			result.color.rgb *= matEmissive.rgb + matAmbient.rgb + matDiffuse.rgb;
		#else
			result.color.rgb *= matAmbient.rgb + matDiffuse.rgb;
		#endif
	#endif

#endif

#if (FLAG1_TEXTURE4 && FLAG1_MATERIAL_REFLECTION)
	float3 R;
	#if (FLAG1_TEXTURE2)
		R = reflect( fragment.viewTangentDir, normalVec);
	#else
		#if (FLAG1_MATERIAL_LIGHT)
			R = reflect( -fragment.viewDir, N);
		#else
			R = reflect( -fragment.viewDir, normalize(fragment.normal.xyz));
		#endif
	#endif
	#if (FLAG2_FAKE_REFLECTION)
		float3 reflectCol = reflectionTexture.Sample(reflectionSampler,R.xy).rgb;
	#else
		float3 reflectCol = reflectionTexture.Sample(reflectionSampler,R).rgb;
	#endif
	#if (FLAG1_MATERIAL_REFLECTION_ADD)
		#if (FLAG1_MATERIAL_REFLECTION_LERP)
			#if (FLAG1_TEXTURE3 || FLAG2_SPECULAR_NORMALMAPALPHA)
				result.color.rgb += reflectCol * matReflectivity * glossCol.r;
			#else
				result.color.rgb += reflectCol * matReflectivity;
			#endif
		#else
			#if (FLAG1_TEXTURE3 || FLAG2_SPECULAR_NORMALMAPALPHA)
				result.color.rgb += reflectCol * glossCol.r;
			#else
				result.color.rgb += reflectCol;
			#endif
		#endif
	#else
		#if (FLAG1_MATERIAL_REFLECTION_LERP)
			#if (FLAG1_TEXTURE3 || FLAG2_SPECULAR_NORMALMAPALPHA)
				result.color.rgb = lerp( result.color.rgb, reflectCol, matReflectivity * glossCol.r);
			#else
				result.color.rgb = lerp( result.color.rgb, reflectCol, matReflectivity);
			#endif
		#else
			#if (FLAG1_TEXTURE3 || FLAG2_SPECULAR_NORMALMAPALPHA)
				result.color.rgb = lerp( result.color.rgb, reflectCol, glossCol.r);
			#else
				result.color.rgb = reflectCol;
			#endif
		#endif
	#endif
#endif

#if (FLAG1_TEXTURE7)
	result.color.rgb *= darkCol;
#endif

#if (FLAG1_TEXTURE8)
	result.color.rgb *= detailCol;
#endif

#if (FLAG1_TEXTURE6)
	result.color.rgb += glowCol;
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR)
	result.color *= fragment.color;
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR || FLAG0_HDR || FLAG0_OUTLINE)
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
#endif

#if (FLAG2_WATER_FRESNEL)
	float A     = refractRatio;
	float B     = min( dot( waterViewDir, normalize(fragment.normal.xyz)), 0.5f /* 0.85f */ );
	float C     = sqrt( 1.f - A * A * (1.f - B * B));
	float Rs    = (A * B - C) * (A * B - C) / ((A * B + C) * (A * B + C));
	float Rp    = (A * C - B) * (A * C - B) / ((A * C + B) * (A * C + B));
	float alpha = (Rs + Rp) / 2.0f;
	result.color.a *= min( alpha, 1.0f);
#endif

#if (FLAG1_MATERIAL_HEIGHTFOG)
	#if (FLAG2_MATERIAL_MODULATE_FOG)
		result.color.rgb *= (1.f - hfAlpha) + heightFogColor.rgb * hfAlpha;
	#else
		result.color.rgb  = lerp( result.color.rgb, heightFogColor.rgb, hfAlpha);
	#endif
#endif

#if (FLAG1_MATERIAL_FOG)
	#if (FLAG2_MATERIAL_MODULATE_FOG)
		float fs = (1.f - fragment.misc.x) * fogColor.a * (1.0f - fogDisable);
		result.color.rgb *= (1.f - fs) + fogColor.rgb * fs;
	#else
		float fs = (1.f - fragment.misc.x) * fogColor.a * (1.0f - fogDisable);
		result.color.rgb = lerp( result.color.rgb, fogColor.rgb, fs );
	#endif
#endif

#if (FLAG0_FLOAT_RENDER_TARGET)
	// 浮動小数点フレームバッファに負の値は出力しないようにする
	result.color.rgb = max( 0.0f, result.color.rgb );
#endif

#if (FLAG0_HDR) && (!FLAG0_FLOAT_RENDER_TARGET)	&& (!FLAG2_REFLECTION_CASTER)	//	#if (FLAG0_HDR_PS3)
	#if (FLAG0_BLOOM)
		float tmp,scl;
		tmp = max( max( result.color.r, result.color.g), max( result.color.b, 0.25));
		scl = 1.0 / tmp;
		result.color = float4(result.color.rgb * scl, 0.2475 * scl);
	#else
		result.color.a = 1.0;
	#endif
#elif (FLAG0_HDR) && (FLAG0_FLOAT_RENDER_TARGET) && (!FLAG2_REFLECTION_CASTER) // 16/12/13
	// 小数バッファとマテリアルのブルームフラグに対応
	#if (FLAG0_BLOOM)
		result.color.a = 0.0f;// 本当は0.998f等にしたいが精度が2bitしかないので
	#else
		result.color.a = 1.0f;
	#endif
#elif (FLAG0_OPAQUE_ALPHA1)
	result.color.a = 1.0;
#endif

//	result.depth = fragment.proj.z / fragment.proj.w;
	return result;
}
 