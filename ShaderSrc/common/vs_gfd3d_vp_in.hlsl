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
	NORMAL_VSINPUT_TYPE normal	 : NORMAL;
#endif
#if (FLAG1_TEXTURE2 && (FLAG1_MATERIAL_LIGHT || FLAG1_MATERIAL_REFLECTION))
	NORMAL_VSINPUT_TYPE binormal	 : BINORMAL;
#endif
};
