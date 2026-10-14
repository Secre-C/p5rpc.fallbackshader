
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
#include "common/ps_gfd_fp_out.hlsl"

/*---------------------------------------------------------------------------*/

#include "common/ps_const_system.hlsl"

#include "common/ps_const_material.hlsl"

#include "common/ps_const_lights.hlsl"

#include "common/ps_const_env_colors.hlsl"

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

#include "common/ps_const_shadow_vsm.hlsl"

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

#include "common/ps_textures.hlsl"

#if (FLAG2_WATER_REFLECTION)
Texture2D		waterReflectTexture : register(t15);
SamplerState	waterReflectSampler : register(s15);
#endif

#include "common/ps_lbuffer.hlsl"


/*---------------------------------------------------------------------------*/

gfdFpOut main( gfd3DVpOut fragment )
{
	gfdFpOut result;
	float3   waterNormal;
	float3   waterDir;

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

#include "common/ps_hfalpha.hlsl"

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

#include "common/ps_apply_textures.hlsl"

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR)
	result.color *= fragment.color;
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR || FLAG0_CONSTANTCOLOR || FLAG0_HDR || FLAG0_OUTLINE)
#include "common/ps_atest_clip.hlsl"
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

#include "common/ps_heightfog.hlsl"

#include "common/ps_fog.hlsl"

#include "common/ps_float_rt.hlsl"

#include "common/ps_hdr.hlsl"

//	result.depth = fragment.proj.z / fragment.proj.w;
	return result;
}
 