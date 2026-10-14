/*---------------------------------------------------------------------------*/
struct gfd3DVpOut
{
	float4 position	 : S_POSITION;

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_MATERIAL_HEIGHTFOG)
	#if (FLAG1_MATERIAL_HEIGHTFOG)
	float4 normal	 : NORMAL;
	#else
	float3 normal	 : NORMAL;
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

#if ((FLAG1_MATERIAL_LIGHT && FLAG1_MATERIAL_SPECULAR) || FLAG1_MATERIAL_REFLECTION)
	#if (FLAG1_TEXTURE2)
	float3 viewTangentDir : TANGENT;
	#else
	float3 viewDir : BINORMAL;
	#endif
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


#include "common/ps_textures.hlsl"

#if (FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER))
#include "common/ps_shadow_samplers.hlsl"
#endif

#include "common/ps_depth_cmp.hlsl"

#include "common/ps_lbuffer.hlsl"


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
	float  D;
	float3 lightAmbient = float3(0,0,0);
	float3 lightDiffuse = float3(0,0,0);

#include "common/ps_normal_select.hlsl"

	#if (FLAG0_DEFERRED)
		float4 lbuffCol;
		float2 bufcoord;
		bufcoord     = fragment.position.xy * resolutionRev.xy;
		lbuffCol     = lbufferTexture.Sample( lbufferSampler, bufcoord.xy );
		lightAmbient = lbuffCol.rgb;
		lightDiffuse = lbuffCol.rgb;
	#endif

	#if (FLAG1_MATERIAL_SPECULAR)

#include "common/ps_specular_lbuff.hlsl"
		#if (FLAG1_TEXTURE2)
			float3 viewDir = normalize(fragment.viewTangentDir);
		#else
			float3 viewDir = normalize(fragment.viewDir);
		#endif
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

				float3 rgb = shadowColor.rgb;//float3(0.f, 0.f, 0.f);

				float3 materialAmb = lerp(rgb, float3(1.f, 1.f, 1.f), shadowAmb);
				float3 materialDif = lerp(rgb, float3(1.f, 1.f, 1.f), shadowDif);

				#if (FLAG1_MATERIAL_EMISSIVE)
					result.color.rgb *= matEmissive.rgb + matAmbient.rgb * materialAmb + matDiffuse.rgb * materialDif;
				#else
					result.color.rgb *= matAmbient.rgb * materialAmb + matDiffuse.rgb * materialDif;
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

#include "common/ps_vertex_color.hlsl"

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