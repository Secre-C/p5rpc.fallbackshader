/*---------------------------------------------------------------------------*/
/* CSM/PCF shadow factor, shared by the 3D pixel shaders.
 *
 * Samples the shadow cascade selected by the interpolated lightcoord(s) and
 * returns the shadow term (0 = fully lit, 1 = fully shadowed). Under
 * FLAG2_CSM the cascades arrive as lcFar/lcMid/lcNear ([0]/[1]/[2] of the
 * interpolated lightcoord array) and the CSM debug tints are multiplied into
 * `color`; the non-CSM path leaves `color` untouched. `bias` is added to the
 * compared depth exactly once, whatever PCF mode is active - the baked
 * sources reached the same arithmetic through different placements of
 * `tx.z += depthBias` (inside the 4x4 branch plus `+ depthBias` on the
 * 3x3/1x1 taps, or a single increment before the mode switch).
 *
 * Must be included after the shadow textures/samplers and the GFD_PSCONST_SHADOW
 * constant buffer are declared.
 *---------------------------------------------------------------------------*/
#if (FLAG2_PCF)
#if (FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER))
float gfdSampleShadow(
#if (FLAG2_CSM)
    float4 lcFar, float4 lcMid, float4 lcNear,
#else
    float4 lc,
#endif
    inout float3 color,
    float bias)
{
	float shadow;

#if (FLAG2_CSM)
	/* ------------------------------------ FLAG2_CSM ------------------------------------*/
	float  w2     = shiftPCF * 2.0f;
	float3 tx     = lcNear.xyz / lcNear.w;
	float2 border = saturate( clamp(tx.xy, w2, 1.0f - w2) ) - tx.xy;
#ifndef NEEDLE_SHADER
	if( any(bit_cast<bool2>(border)) ) {
#else
	if( (abs(border.x) + abs(border.y)) > CSM_EPS ) {
#endif

		tx     = lcMid.xyz / lcMid.w;
		border = saturate( clamp(tx.xy, w2, 1.0f - w2) ) - tx.xy;
#ifndef NEEDLE_SHADER
		if( any(bit_cast<bool2>(border)) ) {
#else
		if( (abs(border.x) + abs(border.y)) > CSM_EPS ) {
#endif

			/*---------- CSM遠景用処理[0] ----------*/

			tx = lcFar.xyz / lcFar.w;

			gfdDepthSampleCmp( shadow, shadowTexture0, shadowSampler, tx.xy, tx.z + bias );

			color *= csmDebugColor[0].rgb;		// 青

		} else {

			/*---------- CSM中景用処理[1] ----------*/
			// tx は直前の境界テスト用の lcMid 除算のまま.

			gfdDepthGatherCmp( shadow, shadowTexture1, shadowSampler, tx.xy, tx.z + bias );

			color *= csmDebugColor[1].rgb;		// 緑
		}

	} else {

		/*---------- CSM近景用処理[2] ----------*/

		tx.z += bias;
		#if (FLAG2_PCF_4x4)
			float shade;
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
			gfdDepthGatherCmp( shadow, shadowTexture2, shadowSampler, tx.xy, tx.z );
		#else
			gfdDepthSampleCmp( shadow, shadowTexture2, shadowSampler, tx.xy, tx.z );
		#endif

		color *= csmDebugColor[2].rgb;	// 赤
	}

#else	/* ------------------------------------ FLAG2_CSM ------------------------------------*/

	float3 tx = lc.xyz / lc.w;
	tx.z += bias;
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
		lightCoord = lcFar.xyz / lcFar.w;
	#else
		lightCoord = lc.xyz / lc.w;
	#endif
	float2 _border = saturate(lightCoord.xy) - lightCoord.xy;
	if( (abs(_border.x) + abs(_border.y)) > CSM_EPS ) {
		shadow = 1.f;
	}
	#endif

	return shadow;
}
#endif /* FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER) */
#endif /* FLAG2_PCF */

/*---------------------------------------------------------------------------*/
/* Poisson-disk PCF + CSM helpers.                                          */
/*                                                                          */
/* These reference shiftPCF / csmDebugColor (declared in                    */
/* ps_const_shadow_pcf.hlsl) and shadowTexture0/1/2, so they must live      */
/* under the same FLAG2_PCF guard as gfdSampleShadow above.                 */
/*---------------------------------------------------------------------------*/
#if (FLAG2_PCF)
#if (FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER))

static const float2 gShadowPoisson[16] =
{
    float2(-0.94201624, -0.39906216),
    float2( 0.94558609, -0.76890725),
    float2(-0.09418410, -0.92938870),
    float2( 0.34495938,  0.29387760),

    float2(-0.91588581,  0.45771432),
    float2(-0.81544232, -0.87912464),
    float2(-0.38277543,  0.27676845),
    float2( 0.97484398,  0.75648379),

    float2( 0.44323325, -0.97511554),
    float2( 0.53742981, -0.47373420),
    float2(-0.26496911, -0.41893023),
    float2( 0.79197514,  0.19090188),

    float2(-0.24188840,  0.99706507),
    float2(-0.81409955,  0.91437590),
    float2( 0.19984126,  0.78641367),
    float2( 0.14383161, -0.14100790)
};

static const float gWeightT[16] =
{
    0.113444000f, 0.045560000f, 0.162910000f, 0.652400000f,
    0.113040000f, 0.050300000f, 0.628800000f, 0.042170000f,
    0.092010000f, 0.343900000f, 0.599800000f, 0.251560000f,
    0.112040000f, 0.044300000f, 0.254340000f, 0.919100000f
};

static const float gWeightW[16] =
{
    0.112662000f, 0.074730000f, 0.132570000f, 0.247560000f,
    0.112470000f, 0.078120000f, 0.243450000f, 0.072170000f,
    0.102540000f, 0.185580000f, 0.238380000f, 0.161220000f,
    0.112020000f, 0.073790000f, 0.162000000f, 0.288810000f
};

static const float gWeightSum = 6.824030601f;
static const float gInvTotalWeight = 0.146540961f;

float ShadowHash(float2 p)
{
    p = floor(p);
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

/* ------------------------------------------------------------------ */
/* Poisson PCF filter. `bias` is passed in explicitly, so the caller   */
/* controls it (matches gfdSampleShadow's convention).                 */
/* ------------------------------------------------------------------ */
float ShadowFilter(Texture2D shadowTexture, float3 tx, float angle, float bias)
{
    float  texel  = shiftPCF;
    float  depth  = tx.z + bias;
    float  s, c;
    sincos(angle, s, c);

    float  result = 0.0;
    float2 texel2 = 2.0 * texel;

    [unroll]
    for (int i = 0; i < 16; ++i)
    {
        float2 g = gShadowPoisson[i];
        float2 p = float2(g.x * c - g.y * s, g.x * s + g.y * c);
        float2 offset = p * texel2;

        float2 uvT = tx.xy + offset;
        float2 uvW = uvT + offset;      // == tx.xy + p * 4 * texel

        float4 cT = shadowTexture.GatherCmp(shadowSampler, uvT, depth);
        float4 cW = shadowTexture.GatherCmp(shadowSampler, uvW, depth);

        result += dot(cT, 0.25) * gWeightT[i];
        result += dot(cW, 0.25) * gWeightW[i];
    }

    return result * gInvTotalWeight;
}

float ShadowEdgeFade(float3 tx, float w2)
{
    float2 d    = min(tx.xy - w2, 1.0 - w2 - tx.xy);
    float  edge = min(d.x, d.y);
    return smoothstep(0.0, max(w2 * 0.5, 1e-5f), edge);
}

/* ------------------------------------------------------------------ */
/* CSM shadow factor. Same inputs as gfdSampleShadow:                  */
/*   - noiseSeed : screen-space seed for the Poisson rotation          */
/*   - lcFar/lcMid/lcNear  (FLAG2_CSM) or lc (non-CSM)                 */
/*   - color     : multiplied by csmDebugColor[i] on the used cascade  */
/*   - bias      : added to compared depth, once                       */
/* Returns 0 = fully lit, 1 = fully shadowed.                          */
/* ------------------------------------------------------------------ */
float ShadowCSM(
    float2 noiseSeed,
#if (FLAG2_CSM)
    float4 lcFar, float4 lcMid, float4 lcNear,
#else
    float4 lc,
#endif
    inout float3 color,
    float bias)
{
    float w2    = shiftPCF * 4.5;
    float angle = ShadowHash(noiseSeed) * 6.28318530718;

#if (FLAG2_CSM)
    /* ---------- near cascade (index 2) ---------- */
    float3 tx2 = lcNear.xyz / lcNear.w;
    if (tx2.x >= w2 && tx2.x <= 1.0 - w2 &&
        tx2.y >= w2 && tx2.y <= 1.0 - w2)
    {
        float fade = ShadowEdgeFade(tx2, w2);
        if (fade < 1.0)
        {
            float3 tx1 = lcMid.xyz / lcMid.w;
            float nearShadow = ShadowFilter(shadowTexture2, tx2, angle, bias);
            float farShadow  = ShadowFilter(shadowTexture1, tx1, angle, bias);
            color *= csmDebugColor[2].rgb;                 // 赤
            return lerp(farShadow, nearShadow, fade);
        }
        color *= csmDebugColor[2].rgb;                     // 赤
        return ShadowFilter(shadowTexture2, tx2, angle, bias);
    }

    /* ---------- mid cascade (index 1) ---------- */
    float3 tx1 = lcMid.xyz / lcMid.w;
    if (tx1.x >= w2 && tx1.x <= 1.0 - w2 &&
        tx1.y >= w2 && tx1.y <= 1.0 - w2)
    {
        float fade = ShadowEdgeFade(tx1, w2);
        if (fade < 1.0)
        {
            float3 tx0 = lcFar.xyz / lcFar.w;
            float nearShadow = ShadowFilter(shadowTexture1, tx1, angle, bias);
            float farShadow  = ShadowFilter(shadowTexture0, tx0, angle, bias);
            color *= csmDebugColor[1].rgb;                 // 緑
            return lerp(farShadow, nearShadow, fade);
        }
        color *= csmDebugColor[1].rgb;                     // 緑
        return ShadowFilter(shadowTexture1, tx1, angle, bias);
    }

    /* ---------- far cascade (index 0) ---------- */
    float3 tx0 = lcFar.xyz / lcFar.w;
    color *= csmDebugColor[0].rgb;                         // 青
    return ShadowFilter(shadowTexture0, tx0, angle, bias);

#else
    /* ---------- single-map path ---------- */
    float3 tx = lc.xyz / lc.w;
    return ShadowFilter(shadowTexture, tx, angle, bias);
#endif
}

#endif /* FLAG1_MATERIAL_SHADOW && (!FLAG2_REFLECTION_CASTER) */

#endif /* FLAG2_PCF */