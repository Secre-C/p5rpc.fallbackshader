#if (FLAG0_FLOAT_RENDER_TARGET)
	// 浮動小数点フレームバッファに負の値は出力しないようにする
	result.color.rgb = max( 0.0f, result.color.rgb );
#endif
