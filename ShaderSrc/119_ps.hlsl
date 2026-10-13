/*---------------------------------------------------------------------------*/
struct gfd3DVpOut
{
	float4 position	 : S_POSITION;

#if (FLAG1_MATERIAL_SHADOW)
	#if (FLAG2_CSM)
	float4 lightcoord[3] : TEXCOORD5;	// TEXCOORD5,6,7
	#else
	float4 lightcoord    : TEXCOORD5;
	#endif
#endif
};

/*---------------------------------------------------------------------------*/
struct gfdFpOut
{
	float4	color	: S_TARGET_OUTPUT0;
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
	float4	shadowColor;
	float4	csmDebugColor[3];
}
#endif

#if (FLAG2_VSM)
ConstantBuffer GFD_PSCONST_SHADOW : register(b6)
{
	float4	vsm;
}
#endif

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

#if (FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER))
SamplerComparisonState	shadowSampler : register(s10);
	#if (FLAG2_CSM)
		Texture2D		shadowTexture0 : register(t10);
		Texture2D		shadowTexture1 : register(t11);	
		Texture2D		shadowTexture2 : register(t12);	
	#else
		Texture2D		shadowTexture    : register(t10);
	#endif
#endif

#define gfdDepthCmp( _texture, _sampler, _uv, _depth )	\
	( (_texture).SampleCmp( _sampler, _uv, _depth ) )

#define gfdDepthSampleCmp( _output, _texture, _sampler, _uv, _depth ) {	\
	(_output) = (_texture).SampleCmp( _sampler, _uv, _depth );			\
}

#define gfdDepthGatherCmp( _output, _texture, _sampler, _uv, _depth ) {	\
	float4 s4 = ( (_texture).GatherCmp( _sampler, _uv, _depth ) );		\
	(_output) = (s4.x + s4.y + s4.z + s4.w) * (1.0f / 4.0f);			\
}

#if (FLAG0_DEFERRED)
Texture2D		lbufferTexture : register(t14);
SamplerState	lbufferSampler : register(s14);
#endif

/*---------------------------------------------------------------------------*/

gfdFpOut main( gfd3DVpOut fragment )
{
	gfdFpOut result;

	result.color = float4( 0, 0, 0, 0 );

#if (FLAG0_OUTLINE)
	result.outline = float4( 0, 0, 0, 1 );
#endif

#if (FLAG1_MATERIAL_SHADOW)
	#if (FLAG2_PCF)
		float  shadow;

		#if (FLAG2_CSM)
			/* ------------------------------------ FLAG2_CSM ------------------------------------*/
			float  w2     = shiftPCF * 2.0f;
			float3 tx     = fragment.lightcoord[2].xyz / fragment.lightcoord[2].w;
			float2 border = saturate( clamp(tx.xy, w2, 1.0f - w2) ) - tx.xy;

#ifndef NEEDLE_SHADER
			if( any(bit_cast<bool2>(border)) ) {
#else
			if( (abs(border.x) + abs(border.y)) > CSM_EPS ) {
#endif

				tx     = fragment.lightcoord[1].xyz / fragment.lightcoord[1].w;
				border = saturate( clamp(tx.xy, w2, 1.0f - w2) ) - tx.xy;
#ifndef NEEDLE_SHADER
				if( any(bit_cast<bool2>(border)) ) {
#else
				if( (abs(border.x) + abs(border.y)) > CSM_EPS ) {
#endif


					/*---------- CSM遠景用処理[0] ----------*/

					tx = fragment.lightcoord[0].xyz / fragment.lightcoord[0].w;

					gfdDepthSampleCmp( shadow, shadowTexture0, shadowSampler, tx.xy, tx.z + depthBias );

					result.color.rgb *= csmDebugColor[0].rgb;		// 青

				} else {

					/*---------- CSM中景用処理[1] ----------*/

					gfdDepthGatherCmp( shadow, shadowTexture1, shadowSampler, tx.xy, tx.z + depthBias );

					result.color.rgb *= csmDebugColor[1].rgb;		// 緑
				}

			} else {

				/*---------- CSM近景用処理[2] ----------*/

				#if (FLAG2_PCF_4x4)
					float shade;
					tx.z += depthBias;
					shade   = gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(-shiftPCF,-shiftPCF), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(     0.0f,-shiftPCF), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2( shiftPCF,-shiftPCF), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(-shiftPCF,     0.0f), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(     0.0f,     0.0f), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2( shiftPCF,     0.0f), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(-shiftPCF, shiftPCF), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(     0.0f, shiftPCF), tx.z );
					shade  += gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2( shiftPCF, shiftPCF), tx.z );
					shadow  = shade * (1.0f / 9.0f);
				#elif (FLAG2_PCF_3x3)
					gfdDepthGatherCmp( shadow, shadowTexture2, shadowSampler, tx.xy, tx.z + depthBias );
					//	float4 shade;
					//	shade.x = gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy, tx.z );
					//	shade.y = gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2( shiftPCF,     0.0f), tx.z );
					//	shade.z = gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2(     0.0f, shiftPCF), tx.z );
					//	shade.w = gfdDepthCmp( shadowTexture2, shadowSampler, tx.xy + float2( shiftPCF, shiftPCF), tx.z );
					//	shadow  = (shade.x + shade.y + shade.z + shade.w) * (1.0f / 4.0f);
				#else
					gfdDepthSampleCmp( shadow, shadowTexture2, shadowSampler, tx.xy, tx.z + depthBias );
				#endif

				result.color.rgb *= csmDebugColor[2].rgb;	// 赤
			}

		#else	/* ------------------------------------ FLAG2_CSM ------------------------------------*/

			float3 tx = fragment.lightcoord.xyz / fragment.lightcoord.w;
			tx.z += depthBias;
			#if (FLAG2_PCF_4x4)
				float shade;
				shade   = gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2(-shiftPCF,-shiftPCF), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2(     0.0f,-shiftPCF), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2( shiftPCF,-shiftPCF), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2(-shiftPCF,     0.0f), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2(     0.0f,     0.0f), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2( shiftPCF,     0.0f), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2(-shiftPCF, shiftPCF), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2(     0.0f, shiftPCF), tx.z );
				shade  += gfdDepthCmp( shadowTexture, shadowSampler, tx.xy + float2( shiftPCF, shiftPCF), tx.z );
				shadow  = shade * (1.0f / 9.0f);
			#elif (FLAG2_PCF_3x3)
				gfdDepthGatherCmp( shadow, shadowTexture, shadowSampler, tx.xy, tx.z );
			#else
				gfdDepthSampleCmp( shadow, shadowTexture, shadowSampler, tx.xy, tx.z );
			#endif

		#endif	/* ------------------------------------ FLAG2_CSM ------------------------------------*/

        #ifdef NEEDLE_SHADER
		float3 lightCoord = 0.f;
		// 簡単のために前の処理と重複するが、コンパイラの最適化に期待.
		#if FLAG2_CSM
			lightCoord = fragment.lightcoord[0].xyz / fragment.lightcoord[0].w;
		#else
			lightCoord = fragment.lightcoord.xyz / fragment.lightcoord.w;
		#endif
		float2 _border = saturate(lightCoord.xy) - lightCoord.xy;
		if( (abs(_border.x) + abs(_border.y)) > CSM_EPS ) {
			shadow = 1.f;
		}
		#endif

		result.color = float4( 0, 0, 0, saturate( ( 1.0 - dimmerAmb ) - shadow ) );

	#endif
#endif

	return result;
}

 