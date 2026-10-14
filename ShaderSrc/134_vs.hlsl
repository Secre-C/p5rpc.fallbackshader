
#define M_PI 3.14159265f

/*---------------------------------------------------------------------------*/
struct gfd3DVpIn
{
	float3 position	 : POSITION;

#if (FLAG1_MATERIAL_VERTEXCOLOR)
	float4 color	 : COLOR0;
#endif

#if (FLAG0_TEXCOORD0IN)
	float2 texcoord0 : TEXCOORD0;
#endif

#if (FLAG0_TEXCOORD1IN)
	float2 texcoord1 : TEXCOORD1;
#endif

#if (FLAG0_TEXCOORD2IN)
	float2 texcoord2 : TEXCOORD2;
#endif

// ストリームに法線があったりなかったりするため問題あるので一番下へ移動して対処
#if (FLAG1_MATERIAL_LIGHT || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE)
	float3 normal	 : NORMAL;
#endif
#if (FLAG1_TEXTURE2 && (FLAG1_MATERIAL_LIGHT || FLAG1_MATERIAL_REFLECTION))
	float3 binormal	 : BINORMAL;
#endif
};

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
		float4 lightcoord[3] : TEXCOORD5;	// TEXCOORD5,6,7 TEXCOORD8予備
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
	float3 texcoord0 : TEXCOORD0;
#endif

#if (FLAG0_TEXCOORD1OUT)
	float3 texcoord1 : TEXCOORD9;
#endif

#if (FLAG0_TEXCOORD2OUT || FLAG2_FAKE_REFLECTION)
	float3 texcoord2 : TEXCOORD10;
#endif

#if (FLAG1_MATERIAL_FOG)
	float4 misc : COLOR1; // COLOR1.x = fog
#endif

};

/*---------------------------------------------------------------------------*/

#include "common/vs_const_system.hlsl"

#include "common/vs_const_transform.hlsl"

#include "common/vs_const_viewproj.hlsl"

#include "common/vs_const_shadow4.hlsl"

#include "common/vs_const_light_vec.hlsl"

#include "common/vs_const_fogfactor.hlsl"

#include "common/vs_const_colors.hlsl"

#include "common/vs_const_uv_transforms.hlsl"

/*---------------------------------------------------------------------------*/
gfd3DVpOut main(gfd3DVpIn vertex)
{
	gfd3DVpOut	result;
	float4		position;

#if (FLAG1_MATERIAL_VERTEXCOLOR) && defined(NEEDLE_SHADER)
	vertex.color.xyzw = vertex.color.wzyx;
#endif


	position = mul( float4(vertex.position, 1.0f), mtxLocalToWorld );
	result.position = mul( position, mtxViewProj);

#if (FLAG2_REFLECTION_CASTER)
	result.worldPos = position;
#endif

#if (FLAG1_MATERIAL_LIGHT || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE)
	float3 normal = mul( vertex.normal.xyz, (float3x3)mtxLocalToWorld );
#endif

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE)
	result.normal.xyz = normal;
#elif (FLAG1_MATERIAL_HEIGHTFOG)
	result.normal.xyz = 0.f;
#endif

#include "common/vs_lightcoord.hlsl"

#if (FLAG1_TEXTURE2 && (FLAG1_MATERIAL_LIGHT || FLAG1_MATERIAL_REFLECTION))
#include "common/vs_tangent_basis.hlsl"
#endif

#if (FLAG1_MATERIAL_LIGHT)

#include "common/vs_light0vec.hlsl"

#include "common/vs_light1vec.hlsl"

#include "common/vs_light2vec.hlsl"

#endif

#if ((FLAG1_MATERIAL_LIGHT && FLAG1_MATERIAL_SPECULAR) || FLAG1_MATERIAL_REFLECTION)
	#if (FLAG1_TEXTURE2)
		#if (FLAG3_REFLECT_TYPE1)
			result.viewTangentDir = normalize( mul( tangentMtx, normalize( eyePosition - position.xyz ) ) );
		#else
			result.viewTangentDir = mul( normalize(eyePosition - position.xyz), transpose(tangentMtx) );
		#endif
	#else
		result.viewDir = normalize(eyePosition - position.xyz);
	#endif
#endif

#include "common/vs_vertex_color.hlsl"

	float threshold;

#if (FLAG0_TEXCOORD0OUT)
	threshold = acos( mtxUV0Transform[0][0] ) * 180.f / M_PI; // 非効率だが互換性維持のためここでデコード
	float4x4 mtxUV0TransformCopy = mtxUV0Transform;
	mtxUV0TransformCopy[0][0] = 1.f;
	mtxUV0TransformCopy[0][1] = 0.f;
	mtxUV0TransformCopy[1][0] = 0.f;
	mtxUV0TransformCopy[1][1] = 1.f;
	mtxUV0TransformCopy[3][0] = 0.f;
	mtxUV0TransformCopy[3][1] = 0.f;
	#if (IN_TEXCOORD0 == 0)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV0TransformCopy).xyz;
		#else
			result.texcoord0 = float3( vertex.texcoord0, 0.f );
		#endif
	#elif (IN_TEXCOORD0 == 1)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV0TransformCopy).xyz;
		#else
			result.texcoord0 = float3( vertex.texcoord1, 0.f );
		#endif
	#elif (IN_TEXCOORD0 == 2)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV0TransformCopy).xyz;
		#else
			result.texcoord0 = float3( vertex.texcoord2, 0.f );
		#endif
	#endif
	result.texcoord0.z = threshold;
#endif

#if (FLAG0_TEXCOORD1OUT)
	threshold = acos( mtxUV1Transform[0][0] ) * 180.f / M_PI; // 非効率だが互換性維持のためここでデコード
	float4x4 mtxUV1TransformCopy = mtxUV1Transform;
	mtxUV1TransformCopy[0][0] = 1.f;
	mtxUV1TransformCopy[0][1] = 0.f;
	mtxUV1TransformCopy[1][0] = 0.f;
	mtxUV1TransformCopy[1][1] = 1.f;
	mtxUV1TransformCopy[3][0] = 0.f;
	mtxUV1TransformCopy[3][1] = 0.f;
	#if (IN_TEXCOORD1 == 0)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV1TransformCopy).xyz;
		#else
			result.texcoord1 = float3( vertex.texcoord0, 0.f );
		#endif
	#elif (IN_TEXCOORD1 == 1)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV1TransformCopy).xyz;
		#else
			result.texcoord1 = float3( vertex.texcoord1, 0.f );
		#endif
	#elif (IN_TEXCOORD1 == 2)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV1TransformCopy).xyz;
		#else
			result.texcoord1 = float3( vertex.texcoord2, 0.f );
		#endif
	#endif
	result.texcoord1.z = threshold;
#endif

#if (FLAG0_TEXCOORD2OUT)
	threshold = acos( mtxUV2Transform[0][0] ) * 180.f / M_PI; // 非効率だが互換性維持のためここでデコード
	float4x4 mtxUV2TransformCopy = mtxUV2Transform;
	mtxUV2TransformCopy[0][0] = 1.f;
	mtxUV2TransformCopy[0][1] = 0.f;
	mtxUV2TransformCopy[1][0] = 0.f;
	mtxUV2TransformCopy[1][1] = 1.f;
	mtxUV2TransformCopy[3][0] = 0.f;
	mtxUV2TransformCopy[3][1] = 0.f;
	#if (IN_TEXCOORD2 == 0)
		#if (FLAG1_MATERIAL_UV2TRANSFORM)
			result.texcoord2 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV2TransformCopy).xyz;
		#else
			result.texcoord2 = float3( vertex.texcoord0, 0.f );
		#endif
	#elif (IN_TEXCOORD2 == 1)
		#if (FLAG1_MATERIAL_UV2TRANSFORM)
			result.texcoord2 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV2TransformCopy).xyz;
		#else
			result.texcoord2 = float3( vertex.texcoord1, 0.f );
		#endif
	#elif (IN_TEXCOORD2 == 2)
		#if (FLAG1_MATERIAL_UV2TRANSFORM)
			result.texcoord2 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV2TransformCopy).xyz;
		#else
			result.texcoord2 = float3( vertex.texcoord2, 0.f );
		#endif
	#endif
	result.texcoord2.z = threshold;
#else
	#if (FLAG2_FAKE_REFLECTION)
		result.texcoord2.xy = mul( normal.xyz, (float3x3)mtxView );
		result.texcoord2.y *= -1.f;
	#endif
#endif

#include "common/vs_fog.hlsl"

	return result;
}
 