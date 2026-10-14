ConstantBuffer GFD_VSCONST_VIEWPROJ : register(b2)
{
	float4x4	mtxViewProj;
	float4x4	mtxView;
	float3		eyePosition;
	float		_reserved_b2;
}
