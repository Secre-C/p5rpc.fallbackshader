
/*---------------------------------------------------------------------------*/
struct gfd3DVpOut
{
	float4 position : S_POSITION;

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_MATERIAL_HEIGHTFOG)
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
	#if (!FLAG2_EDGE_REFERENCE_NORMALMAP)
	float3 viewDir : BINORMAL;
	#endif
#else
	float3 viewDir : BINORMAL;
#endif

#if (!FLAG2_REFLECTION_CASTER)
	#if (FLAG1_MATERIAL_SHADOW)
		#if (FLAG2_CSM)
		float4 lightcoord[3] : TEXCOORD5;	// TEXCOORD5,6,7
		#else
		float4 lightcoord    : TEXCOORD5;
		#endif
	#endif
#endif

	float4 worldPos : POSITION1;

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR)
	float4 color : COLOR0;
#endif

#if (FLAG0_TEXCOORD0OUT)
	float2 texcoord0 : TEXCOORD0;
#endif

#if (FLAG0_TEXCOORD1OUT)
	float2 texcoord1 : TEXCOORD9;
#endif

#if (FLAG0_TEXCOORD2OUT)
	float2 texcoord2 : TEXCOORD10;
#endif

#if (FLAG1_MATERIAL_FOG)
	float4 misc : COLOR1; // COLOR1.x = fog
#endif

};

/*---------------------------------------------------------------------------*/
#include "common/ps_gfd_fp_out.hlsl"

/*---------------------------------------------------------------------------*/

#include "common/ps_const_system.hlsl"

#include "common/ps_const_material.hlsl"

#include "common/ps_const_lights.hlsl"

#include "common/ps_const_env_colors.hlsl"

#include "common/ps_const_shadow_pcf.hlsl"

#include "common/ps_const_shadow_vsm.hlsl"

ConstantBuffer GFD_PSCONST_EDGE : register(b8)
{
	float4	edgeLightColor;
	float	edgeLightThreshold;
	float	edgeLightFactor;
#if (!FLAG2_EDGE_BACKLIGHT)
	float	edgeShadowThreshold;
	float	edgeShadowFactor;
	float4	edgeShadowColor;
#endif
}

ConstantBuffer GFD_PSCONST_SHADOW_EDGE : register(b9)
{
	float	edgeDarkWork_x;		// darkWork( map_uv_x, map_uv_y, grad_pos_y)
	float	edgeDarkWork_y;		// darkWork( map_uv_x, map_uv_y, grad_pos_y)
	float	edgeDarkWork_z;		// darkWork( map_uv_x, map_uv_y, grad_pos_y)
	float	edgeDarkMapPower;	// darkParams0.x
	float	edgeDarkMapHeight;	// darkParams0.y
	float	edgeDarkMapAlpha;	// darkParams0.z
	float	edgeDarkMapScale;	// darkParams0.w
	float	edgeDarkGradHeight;	// darkParams1.x
	float	edgeDarkGradAlpha;	// darkParams1.y

	// 特殊表現用に追加
	float	spExValue0_x;			// 拡張表現値
	float	spExValue0_y;			// 拡張表現値
	float	spExValue0_z;			// 拡張表現値
	float	spExValue1_x;			// 拡張表現値
	float	spExValue1_y;			// 拡張表現値
	float	spExValue1_z;			// 拡張表現値
}


#include "common/ps_textures.hlsl"

Texture2D		edgeDarkTexture : register(t9);
SamplerState	edgeDarkSampler : register(s9);

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

#include "common/ps_depth_cmp.hlsl"


#include "common/ps_lbuffer.hlsl"

/*---------------------------------------------------------------------------*/
#define EDGELIGHT_SHADOW_MIN (0.4f)

/*---------------------------------------------------------------------------*/

#include "common/ps_shadow_sample.hlsl"

gfdFpOut main( gfd3DVpOut fragment )
{
	gfdFpOut result;

	float4 dark;
	float2 dist;

	float3 edgeDarkWork = float3(edgeDarkWork_x,edgeDarkWork_y,edgeDarkWork_z);
	float3 spExValue0 = float3(spExValue0_x,spExValue0_y,spExValue0_z);
	float3 spExValue1 = float3(spExValue1_x,spExValue1_y,spExValue1_z);
 
	float darkMapFade = 1.0f - saturate( ( fragment.worldPos.y - edgeDarkWork.z ) / edgeDarkMapHeight );
	darkMapFade = darkMapFade * darkMapFade;

#if (FLAG1_TEXTURE1)

	#if (FLAG1_TEXTURE7)
		#if (CHANNEL_TEX7 == 0)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord0 + edgeDarkWork.xy) * edgeDarkMapScale );
		#elif (CHANNEL_TEX7 == 1)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord1 + edgeDarkWork.xy) * edgeDarkMapScale );
		#elif (CHANNEL_TEX7 == 2)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord2 + edgeDarkWork.xy) * edgeDarkMapScale );
		#endif
	#else
		#if (CHANNEL_TEX1 == 0)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord0 + edgeDarkWork.xy) * edgeDarkMapScale );
		#elif (CHANNEL_TEX1 == 1)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord1 + edgeDarkWork.xy) * edgeDarkMapScale );
		#elif (CHANNEL_TEX1 == 2)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord2 + edgeDarkWork.xy) * edgeDarkMapScale );
		#endif
	#endif
	
	
	// 合成素材の歪み
	float2 dark_dist = dark.xy * spExValue1.z * darkMapFade;
	#if (FLAG1_TEXTURE7)
		#if (CHANNEL_TEX7 == 0)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord0 + edgeDarkWork.xy) * edgeDarkMapScale + dark_dist );
		#elif (CHANNEL_TEX7 == 1)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord1 + edgeDarkWork.xy) * edgeDarkMapScale + dark_dist );
		#elif (CHANNEL_TEX7 == 2)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord2 + edgeDarkWork.xy) * edgeDarkMapScale + dark_dist );
		#endif
	#else
		#if (CHANNEL_TEX1 == 0)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord0 + edgeDarkWork.xy) * edgeDarkMapScale + dark_dist );
		#elif (CHANNEL_TEX1 == 1)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord1 + edgeDarkWork.xy) * edgeDarkMapScale + dark_dist );
		#elif (CHANNEL_TEX1 == 2)
			dark = edgeDarkTexture.Sample( edgeDarkSampler, (fragment.texcoord2 + edgeDarkWork.xy) * edgeDarkMapScale + dark_dist );
		#endif
	#endif
	

	dist = dark.xy * edgeDarkMapPower * darkMapFade;

	#if (CHANNEL_TEX1 == 0)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord0 + dist );
	#elif (CHANNEL_TEX1 == 1)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord1 + dist );
	#elif (CHANNEL_TEX1 == 2)
		result.color = diffuseTexture.Sample( diffuseSampler, fragment.texcoord2 + dist );
	#endif

#else	/*----- テクスチャなしの場合 -----*/

	dark         = float4(0,0,0,0);
	dist         = float2(0,0);
	result.color = float4(1,1,1,1);
#endif

#if (FLAG1_MATERIAL_AMBDIFF)
	result.color.a *= matDiffuse.a;
#endif

#if (!(FLAG1_MATERIAL_VERTEXCOLOR) && !(FLAG0_CONSTANTCOLOR))
#include "common/ps_atest_clip.hlsl"
#endif

#if (FLAG1_TEXTURE5 && (!FLAG2_EDGE_CAVERNMAP))
	#if (CHANNEL_TEX5 == 0)
		float4 multipleCol = multipleTexture.Sample(multipleSampler,fragment.texcoord0 + dist );
	#elif (CHANNEL_TEX5 == 1)
		float4 multipleCol = multipleTexture.Sample(multipleSampler,fragment.texcoord1 + dist );
	#elif (CHANNEL_TEX5 == 2)
		float4 multipleCol = multipleTexture.Sample(multipleSampler,fragment.texcoord2 + dist );
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
			float3 glossCol = specularTexture.Sample(specularSampler,fragment.texcoord0 + dist ).rgb;
		#elif (CHANNEL_TEX3 == 1)
			float3 glossCol = specularTexture.Sample(specularSampler,fragment.texcoord1 + dist ).rgb;
		#elif (CHANNEL_TEX3 == 2)
			float3 glossCol = specularTexture.Sample(specularSampler,fragment.texcoord2 + dist ).rgb;
		#endif
	#endif
#else
	float glossCol;
#endif

#if (FLAG1_TEXTURE6)
	#if (CHANNEL_TEX6 == 0)
		float3 glowCol = glowTexture.Sample(glowSampler,fragment.texcoord0 + dist ).rgb;
	#elif (CHANNEL_TEX6 == 1)
		float3 glowCol = glowTexture.Sample(glowSampler,fragment.texcoord1 + dist ).rgb;
	#elif (CHANNEL_TEX6 == 2)
		float3 glowCol = glowTexture.Sample(glowSampler,fragment.texcoord2 + dist ).rgb;
	#endif
#endif

//#if (FLAG1_TEXTURE7)
//	#if (CHANNEL_TEX7 == 0)
//		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord0 + dist ).rgb;
//	#elif (CHANNEL_TEX7 == 1)
//		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord1 + dist ).rgb;
//	#elif (CHANNEL_TEX7 == 2)
//		float3 darkCol = darkTexture.Sample(darkSampler,fragment.texcoord2 + dist ).rgb;
//	#endif
//#endif

#if (FLAG1_TEXTURE8)
	#if (CHANNEL_TEX8 == 0)
		float3 detailCol = detailTexture.Sample(detailSampler,fragment.texcoord0 + dist ).rgb;
	#elif (CHANNEL_TEX8 == 1)
		float3 detailCol = detailTexture.Sample(detailSampler,fragment.texcoord1 + dist ).rgb;
	#elif (CHANNEL_TEX8 == 2)
		float3 detailCol = detailTexture.Sample(detailSampler,fragment.texcoord2 + dist ).rgb;
	#endif
	detailCol *= 2.f;
#endif

#if (FLAG1_TEXTURE9)
	#if (CHANNEL_TEX9 == 0)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord0 + dist );
	#elif (CHANNEL_TEX9 == 1)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord1 + dist );
	#elif (CHANNEL_TEX9 == 2)
		float4 lightCol = lightTexture.Sample(lightSampler,fragment.texcoord2 + dist );
	#endif
#endif

#if (FLAG1_TEXTURE2)
	float4 normalCol;
	float3 normalVec;
	#if (CHANNEL_TEX2 == 0)
		normalCol = normalTexture.Sample(normalSampler,fragment.texcoord0 + dist );
	#elif (CHANNEL_TEX2 == 1)
		normalCol = normalTexture.Sample(normalSampler,fragment.texcoord1 + dist );
	#elif (CHANNEL_TEX2 == 2)
		normalCol = normalTexture.Sample(normalSampler,fragment.texcoord2 + dist );
	#endif
	normalVec = normalize( 2.f * normalCol.xyz - 1.f);
	#if (FLAG2_SPECULAR_NORMALMAPALPHA)
		glossCol = normalCol.a;
	#endif
#endif

#include "common/ps_hfalpha.hlsl"

	float darkGradFade = max( min( ( fragment.worldPos.y - edgeDarkWork.z ) / edgeDarkGradHeight, 1.f ), 1.f - edgeDarkGradAlpha);
/*	darkGradFade = darkGradFade * darkGradFade; */

#if (FLAG1_MATERIAL_LIGHT)
	float3 L;
	float3 N;
	float  D = 0.f;
	float  E;
	float  NVW = 0.f;
#if (!FLAG2_EDGE_BACKLIGHT)
//	float  NVD;
#endif
#if (!FLAG2_EDGE_CAVERNMAP)
	float3 edgeLightRGB = edgeLightColor.rgb;
#endif
	float3 lightAmbient = float3(0,0,0);
	float3 lightDiffuse = float3(0,0,0);

	#if (FLAG1_TEXTURE2)
		float3 viewDir = normalize(fragment.viewTangentDir);
	#else
		float3 viewDir = normalize(fragment.viewDir);
	#endif

#include "common/ps_normal_select.hlsl"

	#if (FLAG0_DEFERRED)
		float4 lbuffCol;
		float2 bufcoord;
		bufcoord     = fragment.position.xy * resolutionRev.xy;
		lbuffCol     = lbufferTexture.Sample( lbufferSampler, bufcoord.xy );
		lightAmbient = lbuffCol.rgb;
		lightDiffuse = lbuffCol.rgb;
		#if (!FLAG2_EDGE_CAVERNMAP)
			edgeLightRGB = lerp( edgeLightRGB, lbuffCol.rgb, min( max( lbuffCol.r, max( lbuffCol.g, lbuffCol.b ) ) * 2.0, 1.0 ) );
		#endif
	#endif


	#if (FLAG1_MATERIAL_SPECULAR)
#include "common/ps_specular_lbuff.hlsl"
		float  P = matSpecular.w;
		float3 H;
	#endif

	#if (FLAG0_OUTLINE && (!FLAG2_REFLECTION_CASTER))
		float3 outlineN;
		#if (FLAG1_TEXTURE2)
			outlineN = normalize(fragment.normal.xyz);
		#else
			outlineN = N;
		#endif
		#if (FLAG1_MATERIAL_HEIGHTFOG)
			result.outline.rgb = 0.5f * outlineN * (1.f - hfAlpha) * darkGradFade + 0.5f;
		#else
			result.outline.rgb = 0.5f * outlineN * darkGradFade + 0.5f;
		#endif
		result.outline.a = matOutlineIndex * step( 0.15f, darkGradFade );
	#endif

	#if (FLAG0_LIGHT0_DIRECTION)
		#if (FLAG1_TEXTURE2)
			L = normalize(fragment.light0TangentDir.xyz);
		#else
			L = normalize(fragment.light0Vec.xyz);
		#endif

		E   = dot( L, N);
		D   = saturate( E );
		#if (!FLAG2_EDGE_BACKLIGHT)
			#if (FLAG2_EDGE_REFERENCE_NORMALMAP)
				NVW = saturate( dot( N, lerp( viewDir, N, -min( E, 0.f) ) ));
//				NVD = saturate( dot( N, lerp( viewDir, N,  max( E, 0.f) ) ));
			#else
				float3 refDir = normalize(fragment.viewDir);
				float3 refN   = normalize(fragment.normal.xyz);
				NVW = saturate( dot( refN, lerp( refDir, refN, -min( E, 0.f) ) ));
//				NVD = saturate( dot( refN, lerp( refDir, refN,  max( E, 0.f) ) ));
			#endif
		#else
			#if (FLAG2_EDGE_REFERENCE_NORMALMAP)
				NVW = saturate( dot( N, viewDir) );
			#else
				NVW = saturate( dot( normalize(fragment.normal.xyz), normalize(fragment.viewDir)) );
			#endif
		#endif

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


#include "common/ps_light1.hlsl"

#include "common/ps_light2.hlsl"

#include "common/ps_lightmap.hlsl"

	#if ((FLAG1_MATERIAL_SHADOW) && (!FLAG2_REFLECTION_CASTER))
		#if (FLAG2_PCF)
			float shadow = ShadowCSM(fragment.position.xy,
			#if (FLAG2_CSM)
				fragment.lightcoord[0], fragment.lightcoord[1], fragment.lightcoord[2],
			#else
				fragment.lightcoord,
			#endif
				result.color.rgb, depthBias);

			float shadowAmb = min( shadow + dimmerAmb + shadowDisable, 1.f);
			float shadowDif = min( shadow + dimmerDif + shadowDisable, 1.f);

			float3 rgb = shadowColor.rgb;//float3(0.f, 0.f, 0.f);

			lightAmbient *= lerp(rgb, float3(1.f, 1.f, 1.f), shadowAmb);
			lightDiffuse *= lerp(rgb, float3(1.f, 1.f, 1.f), shadowDif);

			#if (FLAG1_MATERIAL_SPECULAR)
				lightSpecular *= shadowDif;
			#endif
			#if (!FLAG2_EDGE_CAVERNMAP)
				edgeLightRGB *= max( shadowDif, EDGELIGHT_SHADOW_MIN);
			#endif
//			edgeShadowRGB *= max( shadowDif, EDGELIGHT_SHADOW_MIN);
		#else
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
		#if ((FLAG1_MATERIAL_SHADOW) && (!FLAG2_REFLECTION_CASTER))
			#if (FLAG2_PCF)
				float shadow = ShadowCSM(fragment.position.xy,
				#if (FLAG2_CSM)
					fragment.lightcoord[0], fragment.lightcoord[1], fragment.lightcoord[2],
				#else
					fragment.lightcoord,
				#endif
					result.color.rgb, depthBias);

				float shadowAmb = min( shadow + dimmerAmb + shadowDisable, 1.f);
				float shadowDif = min( shadow + dimmerDif + shadowDisable, 1.f);

				#if (FLAG1_MATERIAL_EMISSIVE)
					result.color.rgb *= matEmissive.rgb + matAmbient.rgb * shadowAmb + matDiffuse.rgb * shadowDif;
				#else
					result.color.rgb *= matAmbient.rgb * shadowAmb + matDiffuse.rgb * shadowDif;
				#endif
			#else
			#endif
		#else
			#if (FLAG1_MATERIAL_EMISSIVE)
				result.color.rgb *= matEmissive.rgb + matAmbient.rgb + matDiffuse.rgb;
			#else
				result.color.rgb *= matAmbient.rgb + matDiffuse.rgb;
			#endif
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


//#if (FLAG1_TEXTURE7)
//	result.color.rgb *= darkCol;
//#endif

#if (FLAG1_TEXTURE8)
	result.color.rgb *= detailCol;
#endif

#if (FLAG1_TEXTURE6)
	result.color.rgb += glowCol;
#endif


#if (FLAG1_MATERIAL_LIGHT)
	E = pow(( min( 1.f - NVW, edgeLightThreshold) / edgeLightThreshold), edgeLightFactor);
	#if (!FLAG2_EDGE_BACKLIGHT)
		#if (!FLAG2_EDGE_CAVERNMAP)
			#if (!FLAG2_EDGE_SEMITRANS)
				#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
					#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
						result.color.rgb += edgeLightRGB * light0Diffuse.rgb * E * edgeLightColor.a * normalCol.a;
					#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
						result.color.rgb += edgeLightRGB * light0Diffuse.rgb * E * edgeLightColor.a * result.color.a;
					#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
						result.color.rgb += edgeLightRGB * light0Diffuse.rgb * E * edgeLightColor.a * lightCol.a;
					#else
						result.color.rgb += edgeLightRGB * light0Diffuse.rgb * E * edgeLightColor.a;
					#endif
				#else
					#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
						result.color.rgb += edgeLightRGB * E * edgeLightColor.a * normalCol.a;
					#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
						result.color.rgb += edgeLightRGB * E * edgeLightColor.a * result.color.a;
					#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
						result.color.rgb += edgeLightRGB * E * edgeLightColor.a * lightCol.a;
					#else
						result.color.rgb += edgeLightRGB * E * edgeLightColor.a;
					#endif
				#endif
			#else
				#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB * light0Diffuse.rgb, E * edgeLightColor.a * normalCol.a);
				#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB * light0Diffuse.rgb, E * edgeLightColor.a * result.color.a);
				#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB * light0Diffuse.rgb, E * edgeLightColor.a * lightCol.a);
				#else
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB * light0Diffuse.rgb, E * edgeLightColor.a);
				#endif
			#endif
		#else
			float4 cavernCol;
			float2 caveCoord;
			caveCoord = ((fragment.proj.xy / fragment.proj.w) + 1.f) * 0.5f;
			cavernCol = multipleTexture.Sample( multipleSampler, caveCoord.xy * 5.f);
			#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
				#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb * light0Diffuse.rgb, E * edgeLightColor.a * cavernCol.a * normalCol.a);
				#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb * light0Diffuse.rgb, E * edgeLightColor.a * cavernCol.a * result.color.a);
				#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb * light0Diffuse.rgb, E * edgeLightColor.a * cavernCol.a * lightCol.a);
				#else
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb * light0Diffuse.rgb, E * edgeLightColor.a * cavernCol.a);
				#endif
			#else
				#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * cavernCol.a * normalCol.a);
				#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * cavernCol.a * result.color.a);
				#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * cavernCol.a * lightCol.a);
				#else
					result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * cavernCol.a);
				#endif
			#endif
		#endif

//		E = pow(( min( (1.f - NVD) * NVW, edgeShadowThreshold) / edgeShadowThreshold), edgeShadowFactor);
//		#if (FLAG1_TEXTURE2)
//			D = E * edgeShadowColor.a * normalCol.a;
//		#else
//			D = E * edgeShadowColor.a;
//		#endif
//		result.color.rgb *= (1.f - D) + edgeShadowColor.rgb * D;
	#else
		#if (!FLAG2_EDGE_CAVERNMAP)
			#if (!FLAG2_EDGE_SEMITRANS)
				#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
					result.color.rgb += edgeLightRGB * E * edgeLightColor.a * normalCol.a;
				#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
					result.color.rgb += edgeLightRGB * E * edgeLightColor.a * result.color.a;
				#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
					result.color.rgb += edgeLightRGB * E * edgeLightColor.a * lightCol.a;
				#else
					result.color.rgb += edgeLightRGB * E * edgeLightColor.a;
				#endif
			#else
				#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB, E * edgeLightColor.a * normalCol.a);
				#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB, E * edgeLightColor.a * result.color.a);
				#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB, E * edgeLightColor.a * lightCol.a);
				#else
					result.color.rgb = lerp( result.color.rgb, edgeLightRGB, E * edgeLightColor.a);
				#endif
			#endif
		#else
			float4 cavernCol;
			float2 caveCoord;
			caveCoord = ((fragment.proj.xy / fragment.proj.w) + 1.f) * 0.5f;
			cavernCol = multipleTexture.Sample( multipleSampler, caveCoord.xy * 5.f);
			#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
				result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * normalCol.a);
			#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
				result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * result.color.a);
			#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
				result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a * lightCol.a);
			#else
				result.color.rgb = lerp( result.color.rgb, cavernCol.rgb, E * edgeLightColor.a);
			#endif
		#endif
	#endif

	float darkGradGray = ( result.color.r + result.color.g + result.color.b ) / 3.f;
	result.color.rgb  = lerp( result.color.rgb * darkGradFade, float3( darkGradGray, 0.f, 0.f ), E * ( 1.f - darkGradFade ) );

#else

	result.color.rgb *= darkGradFade;

#endif

#if 0
	result.color.rgb = lerp( result.color.rgb, dark.rgb, edgeDarkMapAlpha * darkMapFade );
#else

	// RGB => HSV変換
	float hsv_max = max( max( dark.r, dark.g ), dark.b );
	float hsv_min = min( min( dark.r, dark.g ), dark.b );
	float3 hsv = float3( hsv_max - hsv_min, hsv_max - hsv_min, hsv_max );
	if( hsv.x > 0.0f )
	{
		if( hsv_max == dark.r )
		{
			hsv.x = ( dark.g - dark.b ) / hsv.x;
			if( hsv.x < 0.0f )
			{
				hsv.x += 6.0f;
			}
		}
		else if( hsv_max == dark.g )
		{
			hsv.x = 2.0f + ( dark.b - dark.r ) / hsv.x;
		}
		else
		{
			hsv.x = 4.0f + ( dark.r - dark.g ) / hsv.x;
		}
	}
	hsv.x /= 6.0f;
	if( hsv_max != 0.0f )
	{
		hsv.y /= hsv_max;
	}
	
	
	// HSVオフセット反映
	hsv += spExValue0.xyz;
	if( 1.0f < hsv.x )
	{
		hsv.x -= 1.0f;
	}
	hsv = saturate( hsv );
	
	// HSV => RGB変換
	float3	spExRGB = float3( hsv.z, hsv.z, hsv.z );
	if( hsv.y > 0.0f )
	{
		hsv.x *= 6.0f;
		int hsv_i = ( int )hsv.x;
		float hsv_f = hsv.x - ( float )hsv_i;
		if( hsv_i == 1 )
		{
			spExRGB.r *= 1.0f - hsv.y * hsv_f;
			spExRGB.b *= 1.0f - hsv.y;
		}
		else if( hsv_i == 2 )
		{
			spExRGB.r *= 1.0f - hsv.y;
			spExRGB.b *= 1.0f - hsv.y * ( 1.0f - hsv_f );
		}
		else if( hsv_i == 3 )
		{
			spExRGB.r *= 1.0f - hsv.y;
			spExRGB.g *= 1.0f - hsv.y * hsv_f;
		}
		else if( hsv_i == 4 )
		{
			spExRGB.r *= 1.0f - hsv.y * ( 1.0f - hsv_f );
			spExRGB.g *= 1.0f - hsv.y;
		}
		else if( hsv_i == 5 )
		{
			
			spExRGB.g *= 1.0f - hsv.y;
			spExRGB.b *= 1.0f - hsv.y * hsv_f;
		}
		else
		{
			spExRGB.g *= 1.0f - hsv.y * ( 1.0f - hsv_f );
			spExRGB.b *= 1.0f - hsv.y;
		}
	}
	
	result.color.rgb = lerp( result.color.rgb, spExRGB.rgb, edgeDarkMapAlpha * darkMapFade );
	
	
	// テクスチャプロジェクション
	{
		float2 texProjectionTexcoord;
		float4 texProjectionCol;
		
		// スクリーン座標に
		texProjectionTexcoord.xy = fragment.position.xy * resolutionRev.xy;
		texProjectionTexcoord.xy = float2( texProjectionTexcoord.x * spExValue1.x, texProjectionTexcoord.y * spExValue1.y );
		texProjectionTexcoord.xy = float2( texProjectionTexcoord.x + spExValue0.x, texProjectionTexcoord.y + spExValue0.y );
		
		texProjectionCol = edgeDarkTexture.Sample( edgeDarkSampler, texProjectionTexcoord.xy );
		result.color.rgb = lerp( result.color.rgb, texProjectionCol.rgb, spExValue0.z * texProjectionCol.a );
	}
	
	
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR)
	#if (FLAG0_GRAYSCALE)
		float gray = ( result.color.r + result.color.g + result.color.b ) / 3.f;
		result.color.rgb = lerp( result.color.rgb, float3( gray, gray, gray ), fragment.color.a );
	#endif
	#if (FLAG0_COLOR_OP_LERP)
		result.color.rgb = lerp( result.color.rgb, fragment.color.rgb, fragment.color.a);
	#else
		result.color *= fragment.color;
	#endif
	#if (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
		result.color.a = fragment.color.a;
	#endif
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR || FLAG0_HDR || FLAG0_OUTLINE)
#include "common/ps_atest_clip.hlsl"
#endif

#include "common/ps_heightfog.hlsl"

#include "common/ps_fog.hlsl"

#include "common/ps_float_rt.hlsl"

#include "common/ps_hdr.hlsl"

//	result.depth = fragment.proj.z / fragment.proj.w;
	return result;
}
 