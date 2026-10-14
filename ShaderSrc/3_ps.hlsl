
/*---------------------------------------------------------------------------*/
struct gfd3DVpOut
{
	float4 position	: S_POSITION;

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_MATERIAL_HEIGHTFOG)
	#if (FLAG1_MATERIAL_HEIGHTFOG)
	float4 normal	: NORMAL;
	#else
	float3 normal	: NORMAL;
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
#else
	float4 worldPos : TEXCOORD5;
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR)
	float4 color : COLOR0;
#endif

#if (FLAG0_TEXCOORD0OUT)
	float2 texcoord0 : TEXCOORD0;
#endif

#if (FLAG0_TEXCOORD1OUT)
	float2 texcoord1 : TEXCOORD9;
#endif

#if (FLAG0_TEXCOORD2OUT || FLAG2_FAKE_REFLECTION)
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


#include "common/ps_textures.hlsl"

#if (FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER))
#include "common/ps_shadow_samplers.hlsl"
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

#include "common/ps_sample_tex1.hlsl"


#if (FLAG1_MATERIAL_AMBDIFF)
	result.color.a *= matDiffuse.a;
#endif

#if (!(FLAG1_MATERIAL_VERTEXCOLOR) && !(FLAG0_CONSTANTCOLOR))
#include "common/ps_atest_clip.hlsl"
#endif

#if (FLAG1_TEXTURE5 && (!FLAG2_EDGE_CAVERNMAP))
#include "common/ps_sample_tex5.hlsl"
#endif

#if (!FLAG2_SPECULAR_NORMALMAPALPHA)
	#if (FLAG1_TEXTURE3)
#include "common/ps_sample_tex3.hlsl"
	#endif
#else
	float glossCol;
#endif

#if (FLAG1_TEXTURE6)
#include "common/ps_sample_tex6.hlsl"
#endif

#if (FLAG1_TEXTURE7)
#include "common/ps_sample_tex7.hlsl"
#endif

#if (FLAG1_TEXTURE8)
#include "common/ps_sample_tex8.hlsl"
#endif

#if (FLAG1_TEXTURE9)
#include "common/ps_sample_tex9.hlsl"
#endif

#include "common/ps_sample_tex2.hlsl"

#include "common/ps_hfalpha.hlsl"

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

#include "common/ps_outline.hlsl"

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

#include "common/ps_reflection.hlsl"


#include "common/ps_apply_textures.hlsl"


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

#if (FLAG0_FLOAT_RENDER_TARGET)
	// 浮動小数点フレームバッファ用に負の値は出力しないようにする
	result.color = max( 0.0f, result.color );
#endif

#include "common/ps_hdr.hlsl"

//	result.depth = fragment.proj.z / fragment.proj.w;
	return result;
}

 