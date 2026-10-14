
/*---------------------------------------------------------------------------*/
struct gfd3DVpOut
{
	float4 position : S_POSITION;

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || (!FLAG2_TOON_REFERENCE_NORMALMAP) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_MATERIAL_HEIGHTFOG)
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

ConstantBuffer GFD_PSCONST_TOON : register(b8)
{
	float4	toonLightColor;
	float	toonLightThreshold;
	float	toonLightFactor;
	float	toonShadowBrightness;
	float	toonShadowThreshold;
	float	toonShadowFactor;
}


#include "common/ps_textures.hlsl"

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
#define TOONLIGHT_SHADOW_MIN (0.4f)

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

#if (FLAG1_TEXTURE5)
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
	float  NL;
	float  D = 0.f;
	float  E;
	float  NVW = 0.f;
	float3 lightAmbient = float3(0,0,0);
	float3 lightDiffuse = float3(0,0,0);
	float3 toonLightRGB = toonLightColor.rgb;

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
//		lightAmbient = lbuffCol.rgb * 0.40f;
//		lightDiffuse = lbuffCol.rgb * 0.40f;
		toonLightRGB = lerp( toonLightRGB, lbuffCol.rgb, min( max( lbuffCol.r, max( lbuffCol.g, lbuffCol.b ) ) * 2.0, 1.0 ) );
	#endif

	#if (FLAG1_MATERIAL_SPECULAR)
#include "common/ps_specular_lbuff.hlsl"
		float  P = matSpecular.w;
		float3 H;
	#endif

#include "common/ps_outline.hlsl"

	#if (FLAG0_LIGHT0_DIRECTION)
		#if (FLAG1_TEXTURE2)
			L = normalize(fragment.light0TangentDir);
		#else
			L = normalize(fragment.light0Vec.xyz);
		#endif

		E = dot( L, N);
		#if (FLAG2_EDGE_REFERENCE_NORMALMAP)
			NVW = saturate( dot( N, lerp( viewDir, N, -min( E, 0.f) ) ));
		#else
			#if (FLAG1_TEXTURE2)
				float3 refDir = normalize(fragment.viewDir);
				float3 refN   = normalize(fragment.normal.xyz);
				float  refE   = dot( normalize(fragment.light0Vec.xyz), refN);
				NVW = saturate( dot( refN, lerp( refDir, refN, -min( refE, 0.f) ) ));
			#else
				NVW = saturate( dot( N, lerp( viewDir, N, -min( E, 0.f) ) ));
			#endif
		#endif

		#if (FLAG2_TOON_REFERENCE_NORMALMAP)
			NL = saturate( E );
			D  = saturate(max(NL - pow( toonShadowThreshold, 1.8f), 0.f) * toonShadowFactor );
		#else
			#if (FLAG1_TEXTURE2)
				#if (FLAG2_EDGE_REFERENCE_NORMALMAP)
					float refE = dot( normalize(fragment.light0Vec.xyz), normalize(fragment.normal.xyz));
				#endif
				NL = saturate( refE );
				D  = saturate(max(NL - pow( toonShadowThreshold, 1.8f), 0.f) * toonShadowFactor );
			#else
				NL = saturate( E );
				D  = saturate(max(NL - pow( toonShadowThreshold, 1.8f), 0.f) * toonShadowFactor );
			#endif
		#endif

		lightAmbient += light0Ambient.rgb;
		lightDiffuse += light0Diffuse.rgb;
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

		NL = saturate( dot( L, N) );
		D  = saturate(max(NL - pow( toonShadowThreshold, 1.8f), 0.f) * toonShadowFactor ) * A;

		lightAmbient += light0Ambient.rgb * A;
		lightDiffuse += light0Diffuse.rgb;
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

		NL = saturate( dot( L, N) );
		D  = saturate(max(NL - pow( toonShadowThreshold, 1.8f), 0.f) * toonShadowFactor );

		lightAmbient += light0Ambient.rgb;
		lightDiffuse += light0Diffuse.rgb;
		#if (FLAG1_MATERIAL_SPECULAR)
			H = normalize(L + viewDir);
			lightSpecular += light0Specular.rgb * pow( max( dot( H, N), 0.f), P);
		#endif
	#endif


#include "common/ps_light1.hlsl"

#include "common/ps_light2.hlsl"

	#if (FLAG1_TEXTURE9)
		//lightAmbient += lmapAmbient;
		#if (FLAG2_LIGHTMAP_MODULATE)
		#elif (FLAG1_LIGHTMAP_MODULATE2)
		#else
			lightDiffuse += lightCol.rgb;
		#endif
	#endif

	#if ((FLAG1_MATERIAL_SHADOW) && (!FLAG2_REFLECTION_CASTER))
		#if (FLAG2_PCF)
			float shadow = ShadowCSM(fragment.position.xy,
			#if (FLAG2_CSM)
				fragment.lightcoord[0], fragment.lightcoord[1], fragment.lightcoord[2],
			#else
				fragment.lightcoord,
			#endif
				result.color.rgb, depthBias);

			float shadowDif = min( shadow + dimmerDif + shadowDisable, 1.f);

			D *= shadow;
			#if (FLAG1_MATERIAL_SPECULAR)
				lightSpecular *= shadowDif;
			#endif
			toonLightRGB *= max( shadowDif, TOONLIGHT_SHADOW_MIN);
		#else
		#endif
	#endif

	#if (FLAG1_MATERIAL_AMBDIFF)
		#if (FLAG1_TEXTURE9 && FLAG2_LIGHTMAP_MODULATE)
			float lightMapMod;
			lightMapMod  = 1.f - lightCol.r;
			#if (FLAG1_MATERIAL_EMISSIVE)
				result.color.rgb *= matEmissive.rgb + lerp( matAmbient.rgb * lightAmbient, lightAmbient + matDiffuse.rgb * lightDiffuse, saturate(toonShadowBrightness + D + lightMapMod));
			#else
				result.color.rgb *= lerp( matAmbient.rgb * lightAmbient, lightAmbient + matDiffuse.rgb * lightDiffuse, saturate(toonShadowBrightness + D + lightMapMod));
			#endif
		#elif (FLAG1_TEXTURE9 && FLAG1_LIGHTMAP_MODULATE2)
			float lightMapMod;
			lightMapMod  = 1.f - lightCol.r;
			#if (FLAG1_MATERIAL_EMISSIVE)
				result.color.rgb *= matEmissive.rgb + lerp( matAmbient.rgb * lightAmbient, lightAmbient + matDiffuse.rgb * lightDiffuse, saturate(toonShadowBrightness + D * lightMapMod));
			#else
				result.color.rgb *= lerp( matAmbient.rgb * lightAmbient, lightAmbient + matDiffuse.rgb * lightDiffuse, saturate(toonShadowBrightness + D * lightMapMod));
			#endif
		#else
			#if (FLAG1_MATERIAL_EMISSIVE)
				result.color.rgb *= matEmissive.rgb + lerp( matAmbient.rgb * lightAmbient, lightAmbient + matDiffuse.rgb * lightDiffuse, saturate(toonShadowBrightness + D));
			#else
				result.color.rgb *= lerp( matAmbient.rgb * lightAmbient, lightAmbient + matDiffuse.rgb * lightDiffuse, saturate(toonShadowBrightness + D));
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
	E = pow(( min( 1.f - NVW, toonLightThreshold) / toonLightThreshold), toonLightFactor);
	#if (!FLAG2_EDGE_SEMITRANS)
		#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
			#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
				result.color.rgb += toonLightRGB * light0Diffuse.rgb * E * toonLightColor.a * normalCol.a;
			#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
				result.color.rgb += toonLightRGB * light0Diffuse.rgb * E * toonLightColor.a * result.color.a;
			#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
				result.color.rgb += toonLightRGB * light0Diffuse.rgb * E * toonLightColor.a * lightCol.a;
			#else
				result.color.rgb += toonLightRGB * light0Diffuse.rgb * E * toonLightColor.a;
			#endif
		#else
			#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
				result.color.rgb += toonLightRGB * E * toonLightColor.a * normalCol.a;
			#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
				result.color.rgb += toonLightRGB * E * toonLightColor.a * result.color.a;
			#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
				result.color.rgb += toonLightRGB * E * toonLightColor.a * lightCol.a;
			#else
				result.color.rgb += toonLightRGB * E * toonLightColor.a;
			#endif
		#endif
	#else
		#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
			#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
				result.color.rgb = lerp( result.color.rgb, toonLightRGB * light0Diffuse.rgb, E * toonLightColor.a * normalCol.a);
			#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
				result.color.rgb = lerp( result.color.rgb, toonLightRGB * light0Diffuse.rgb, E * toonLightColor.a * result.color.a);
			#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
				result.color.rgb = lerp( result.color.rgb, toonLightRGB * light0Diffuse.rgb, E * toonLightColor.a * lightCol.a);
			#else
				result.color.rgb = lerp( result.color.rgb, toonLightRGB * light0Diffuse.rgb, E * toonLightColor.a);
			#endif
		#else
			#if (FLAG2_EDGE_REFERENCE_NORMALALPHA)
				result.color.rgb = lerp( result.color.rgb, toonLightRGB, E * toonLightColor.a * normalCol.a);
			#elif (FLAG2_EDGE_REFERENCE_DIFFUSEALPHA)
				result.color.rgb = lerp( result.color.rgb, toonLightRGB, E * toonLightColor.a * result.color.a);
			#elif (FLAG1_EDGE_REFERENCE_LIGHTALPHA)
				result.color.rgb = lerp( result.color.rgb, toonLightRGB, E * toonLightColor.a * lightCol.a);
			#else
				result.color.rgb = lerp( result.color.rgb, toonLightRGB, E * toonLightColor.a);
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

#include "common/ps_float_rt.hlsl"

#include "common/ps_hdr.hlsl"

//	result.depth = fragment.proj.z / fragment.proj.w;
	return result;
}


 