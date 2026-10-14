		#if (!(FLAG0_DEFERRED))
		float3 lightSpecular = float3(0,0,0);
		#else
			#if (FLAG0_LIGHT0_DIRECTION || FLAG0_LIGHT0_POINT || FLAG0_LIGHT0_SPOT)
				float3 lightSpecular = light0Specular.rgb * lbuffCol.w;
			#else
				float3 lightSpecular = float3( lbuffCol.w );
			#endif
		#endif
