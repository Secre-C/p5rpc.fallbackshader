#if (FLAG1_TEXTURE4 && FLAG1_MATERIAL_REFLECTION)
	#if ((!FLAG0_TEXCOORD2OUT) && FLAG2_FAKE_REFLECTION && FLAG3_REFLECT_TYPE1)
		float3 reflectCol = reflectionTexture.Sample(reflectionSampler, fragment.texcoord2.xy * 0.5f + 0.5f );
	#else
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
