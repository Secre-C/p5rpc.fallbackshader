
/*---------------------------------------------------------------------------*/
struct gfd3DVpIn
{
	float3 position : POSITION;

#if (FLAG1_MATERIAL_VERTEXCOLOR)
	float4 color  : COLOR0;
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
#if (FLAG1_MATERIAL_LIGHT  || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || (!FLAG2_TOON_REFERENCE_NORMALMAP) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_TEXTURE2)
	NORMAL_VSINPUT_TYPE normal : NORMAL;
#endif
#if (FLAG1_TEXTURE2)
	NORMAL_VSINPUT_TYPE binormal : BINORMAL;
#endif
};

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

ConstantBuffer GFD_VSCONST_SYSTEM : register(b0)
{
	float4		zeroVec;
	float4		constants;
	float3		scale2D;
}

ConstantBuffer GFD_VSCONST_TRANSFORM : register(b1)
{
	float4x4	mtxLocalToWorld;
	// float3x3	mtxNormal;
}

ConstantBuffer GFD_VSCONST_VIEWPROJ : register(b2)
{
	float4x4	mtxViewProj;
	float4x4	mtxView;
	float3		eyePosition;
	float		_reserved_b2;
}

ConstantBuffer GFD_VSCONST_SHADOW : register(b3)
{
	float4x4	mtxLightViewProj[4];
}

ConstantBuffer GFD_VSCONST_LIGHT_VEC : register(b4)
{
	float4		light0Vec;
	float4		light1Vec;
	float4		light2Vec;
}

ConstantBuffer GFD_VSCONST_FOGFACTOR : register(b5)
{
	float4		fog;
	float2		heightFog;
	float2		_reserved_b5;
}

ConstantBuffer GFD_VSCONST_COLORS : register(b6)
{
	float4		constantColor;
}

ConstantBuffer GFD_VSCONST_UV0_TRANSFORM : register(b10)
{
	float4x4	mtxUV0Transform;
}

ConstantBuffer GFD_VSCONST_UV1_TRANSFORM : register(b11)
{
	float4x4	mtxUV1Transform;
}

ConstantBuffer GFD_VSCONST_UV2_TRANSFORM : register(b12)
{
	float4x4	mtxUV2Transform;
}

/*---------------------------------------------------------------------------*/
gfd3DVpOut main(gfd3DVpIn vertex)
{
	gfd3DVpOut	result;
	float4		position;

#if defined(NEEDLE_SHADER)
#if (FLAG1_MATERIAL_VERTEXCOLOR)
	vertex.color.xyzw = vertex.color.wzyx;
#endif
#if (FLAG1_MATERIAL_LIGHT  || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || (!FLAG2_TOON_REFERENCE_NORMALMAP) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_TEXTURE2)
	vertex.normal = UnpackVSNormal(vertex.normal);
#endif
#if  (FLAG1_TEXTURE2)
	vertex.binormal = UnpackVSNormal(vertex.binormal);
#endif
#endif

	position = mul( float4(vertex.position, 1.0f), mtxLocalToWorld);

	result.position = mul( position, mtxViewProj);

#if (FLAG2_REFLECTION_CASTER)
	result.worldPos = position;
#endif

#if (FLAG1_MATERIAL_LIGHT || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE || FLAG1_TEXTURE2 || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || (!FLAG2_TOON_REFERENCE_NORMALMAP))
	float3 normal = mul( vertex.normal.xyz, (float3x3)mtxLocalToWorld);
#endif

#if ((FLAG1_MATERIAL_LIGHT && (!FLAG1_TEXTURE2)) || (!FLAG2_EDGE_REFERENCE_NORMALMAP) || (!FLAG2_TOON_REFERENCE_NORMALMAP) || FLAG1_MATERIAL_REFLECTION || FLAG0_OUTLINE)
	result.normal.xyz = normal;
#elif (FLAG1_MATERIAL_HEIGHTFOG)
	result.normal.xyz = 0.f;
#endif

#if ((FLAG1_MATERIAL_SHADOW) && (!FLAG2_REFLECTION_CASTER))
	#if (FLAG2_CSM)
	result.lightcoord[0] = mul( position, mtxLightViewProj[0]);
	result.lightcoord[1] = mul( position, mtxLightViewProj[1]);
	result.lightcoord[2] = mul( position, mtxLightViewProj[2]);
	#else
	result.lightcoord = mul( position, mtxLightViewProj[0]);
	#endif
#endif

#if (FLAG1_TEXTURE2)
	float3   binormal   = mul( vertex.binormal.xyz, (float3x3)mtxLocalToWorld);
	float3   tangent    = cross( normal, binormal);
	float3x3 tangentMtx = { tangent, binormal, normal};
#endif

#if (FLAG1_MATERIAL_LIGHT)

	#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
		#if (FLAG0_LIGHT0_DIRECTION)
			#if (FLAG2_TOON_REMOVAL_LIGHT_YAXIS)
				float3 rYn = normalize( float3( light0Vec.x, 0.0f, light0Vec.z ) );
				result.light0Vec = float4( rYn.xyz, light0Vec.w);
				#if (FLAG1_TEXTURE2)
				result.light0TangentDir = float4( mul( rYn.xyz, transpose(tangentMtx) ) , 1.f);
				#endif
			#else
				result.light0Vec = light0Vec;
				#if (FLAG1_TEXTURE2)
				result.light0TangentDir = float4( mul( light0Vec.xyz, transpose(tangentMtx) ) , 1.f);
				#endif
			#endif
		#else
			result.light0Vec = light0Vec - position;
			#if (FLAG1_TEXTURE2)
			result.light0TangentDir = float4( mul( normalize(result.light0Vec.xyz), transpose(tangentMtx) ) , 1.f);
			#endif
		#endif
	#endif

	#if (FLAG0_LIGHT1_DIRECTION || FLAG0_LIGHT1_POINT || FLAG0_LIGHT1_SPOT)
		#if (FLAG0_LIGHT1_DIRECTION)
		result.light1Vec = light1Vec;
		#else
		result.light1Vec = light1Vec - position;
		#endif
	#endif

	#if (FLAG0_LIGHT2_DIRECTION || FLAG0_LIGHT2_POINT || FLAG0_LIGHT2_SPOT)
		#if (FLAG0_LIGHT2_DIRECTION)
		result.light2Vec = light2Vec;
		#else
		result.light2Vec = light2Vec - position;
		#endif
	#endif
#endif

#if (FLAG1_TEXTURE2)
	#if (FLAG3_REFLECT_TYPE1)
		result.viewTangentDir = normalize( mul( tangentMtx, normalize( eyePosition - position.xyz ) ) );
	#else
		result.viewTangentDir = mul( normalize(eyePosition - position.xyz), transpose(tangentMtx) );
	#endif
	#if (!FLAG2_EDGE_REFERENCE_NORMALMAP)
		result.viewDir = normalize(eyePosition - position.xyz);
	#endif
#else
	result.viewDir = normalize(eyePosition - position.xyz);
#endif

#if (FLAG1_MATERIAL_VERTEXCOLOR)
	#if (FLAG0_CONSTANTCOLOR)
		result.color = vertex.color * constantColor;
	#else
		result.color = vertex.color;
	#endif
#else
	#if (FLAG0_CONSTANTCOLOR)
		result.color = constantColor;
	#endif
#endif

#if (FLAG0_TEXCOORD0OUT)
	#if (IN_TEXCOORD0 == 0)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV0Transform);
		#else
			result.texcoord0 = vertex.texcoord0;
		#endif
	#elif (IN_TEXCOORD0 == 1)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV0Transform);
		#else
			result.texcoord0 = vertex.texcoord1;
		#endif
	#elif (IN_TEXCOORD0 == 2)
		#if (FLAG1_MATERIAL_UV0TRANSFORM)
			result.texcoord0 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV0Transform);
		#else
			result.texcoord0 = vertex.texcoord2;
		#endif
	#endif
#endif

#if (FLAG0_TEXCOORD1OUT)
	#if (IN_TEXCOORD1 == 0)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV1Transform);
		#else
			result.texcoord1 = vertex.texcoord0;
		#endif
	#elif (IN_TEXCOORD1 == 1)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV1Transform);
		#else
			result.texcoord1 = vertex.texcoord1;
		#endif
	#elif (IN_TEXCOORD1 == 2)
		#if (FLAG1_MATERIAL_UV1TRANSFORM)
			result.texcoord1 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV1Transform);
		#else
			result.texcoord1 = vertex.texcoord2;
		#endif
	#endif
#endif

#if (FLAG0_TEXCOORD2OUT)
	#if (IN_TEXCOORD2 == 0)
		#if (FLAG1_MATERIAL_UV2TRANSFORM)
			result.texcoord2 = mul( float4( vertex.texcoord0.x, vertex.texcoord0.y, 0.0, 1.0), mtxUV2Transform);
		#else
			result.texcoord2 = vertex.texcoord0;
		#endif
	#elif (IN_TEXCOORD2 == 1)
		#if (FLAG1_MATERIAL_UV2TRANSFORM)
			result.texcoord2 = mul( float4( vertex.texcoord1.x, vertex.texcoord1.y, 0.0, 1.0), mtxUV2Transform);
		#else
			result.texcoord2 = vertex.texcoord1;
		#endif
	#elif (IN_TEXCOORD2 == 2)
		#if (FLAG1_MATERIAL_UV2TRANSFORM)
			result.texcoord2 = mul( float4( vertex.texcoord2.x, vertex.texcoord2.y, 0.0, 1.0), mtxUV2Transform);
		#else
			result.texcoord2 = vertex.texcoord2;
		#endif
	#endif
#else
	#if (FLAG2_FAKE_REFLECTION)
		result.texcoord2.xy = mul( normal.xyz, (float3x3)mtxView );
		result.texcoord2.y *= -1.f;
	#endif
#endif

#if (FLAG1_MATERIAL_FOG)
	float4 view = mul( position, mtxView);

#if 1 // 2015/09/04 niida
	float z      = -view.z;
	float param0 = fog.y;
	float param1 = fog.z;
	float fraction;

	if( fog.w == 0.f )
	{
		// linear
		fraction = z * param1 + ( param0 - 1.0f );
	}else
	if( fog.w == 1.f )
	{
		// exponential
		float dist = 11.084f * ( param1 * z + param0 - 1.5f );
		fraction   = exp( dist );
	}else{
		// exponential2
		float dist = 4.709f * ( param1 * z + param0 - 1.5f );
		fraction   = exp( -( dist * dist ) );
	}

	result.misc.x   = saturate( fraction );
	result.misc.yzw = 0;
#else
	result.misc   = 0;
	result.misc.x = clamp( (fog.y + view.z) * fog.z, 0.0f, 1.0f);
#endif

#endif

#if (FLAG1_MATERIAL_HEIGHTFOG)
	result.normal.w = heightFog.x + position.y * heightFog.y;
#endif

	return result;
}


 