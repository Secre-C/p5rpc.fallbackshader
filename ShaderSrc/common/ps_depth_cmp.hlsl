#define gfdDepthCmp( _texture, _sampler, _uv, _depth )	\
	( (_texture).SampleCmp( _sampler, _uv, _depth ) )

#define gfdDepthSampleCmp( _output, _texture, _sampler, _uv, _depth ) {	\
	(_output) = (_texture).SampleCmp( _sampler, _uv, _depth );			\
}

#define gfdDepthGatherCmp( _output, _texture, _sampler, _uv, _depth ) {	\
	float4 s4 = ( (_texture).GatherCmp( _sampler, _uv, _depth ) );		\
	(_output) = (s4.x + s4.y + s4.z + s4.w) * (1.0f / 4.0f);			\
}
