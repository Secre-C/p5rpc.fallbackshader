struct gfdFpOut
{
	float4	color	: S_TARGET_OUTPUT0;
//	float	depth	: S_DEPTH_OUTPUT;
#if (FLAG0_OUTLINE)
	float4	outline	: S_TARGET_OUTPUT1;
#endif
};
