// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Custom/Visualizer"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_ReflectionTex("ReflectionTex", 2D) = "white" {}
		_Center("Center", Vector) = (0,0,0,0)
		_Spectra("Spectra", Vector) = (0,0,0,0)
		_RingEmission("RingEmission", Float) = 10
		_RingThicknessMax("RingThicknessMax", Float) = 0.5
		_RingThicknessMin("RingThicknessMin", Float) = 0.1
		_RingSrtide("RingSrtide", Float) = 0.2
		_RingSpeedMin("RingSpeedMin ", Float) = 0.2
		_RingSpeedMax("RingSpeedMax", Float) = 0.5
		_GridEmission("GridEmission", Float) = 8
		_ReflectionStrength("ReflectionStrength", Float) = 0.2
		_GridColor("GridColor", Vector) = (0.2,0.3,0.5,0)
		[HideInInspector]_ReflectionDepthTex("ReflectionDepthTex", 2D) = "white" {}
		_BaseColor("Base Color", Color) = (0,0,0,0)
		[Toggle(_SHOWGRID_ON)] _ShowGrid("Show Grid", Float) = 1

		[HideInInspector]_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		[HideInInspector]_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		[HideInInspector]_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		[HideInInspector]_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		[HideInInspector]_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		[HideInInspector]_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		[HideInInspector]_TessMin( "Tess Min Distance", Float ) = 10
		[HideInInspector]_TessMax( "Tess Max Distance", Float ) = 25
		[HideInInspector]_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		[HideInInspector]_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Back
		HLSLINCLUDE
		#pragma target 2.0

		float  _gl_mod(float  a, float  b) { return a - b * floor(a/b); }
		float2 _gl_mod(float2 a, float2 b) { return a - b * floor(a/b); }
		float3 _gl_mod(float3 a, float3 b) { return a - b * floor(a/b); }
		float4 _gl_mod(float4 a, float4 b) { return a - b * floor(a/b); }

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero , One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_SCREEN_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _SHOWGRID_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Spectra;
			float4 _BaseColor;
			float3 _Center;
			float3 _GridColor;
			float _RingSpeedMin;
			float _ReflectionStrength;
			float _GridEmission;
			float _RingThicknessMax;
			float _RingThicknessMin;
			float _RingSpeedMax;
			float _RingSrtide;
			float _RingEmission;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _ReflectionDepthTex;
			sampler2D _ReflectionTex;
			float4x4 _ViewProjectInverse;


			float Hex( float2 p , float2 h )
			{
				float2 q = abs(p);
							return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
			}
			
			float HexGrid( float3 p )
			{
						float scale = 1.2;
							float2 grid = float2(0.692, 0.4) * scale;
							float radius = 0.22 * scale;
							float2 p1 = _gl_mod(p.xz, grid) - grid*0.5;
							float c1 = Hex(p1, radius);
							float2 p2 = _gl_mod(p.xz+grid*0.5, grid) - grid*0.5;
							float c2 = Hex(p2, radius);
							return min(c1, c2);
			}
			
			float3 GuessNormal( float3 p )
			{
							const float d = 0.01;
							return normalize( float3(
								HexGrid(p+float3(  d,0.0,0.0))-HexGrid(p+float3( -d,0.0,0.0)),
								HexGrid(p+float3(0.0,  d,0.0))-HexGrid(p+float3(0.0, -d,0.0)),
								HexGrid(p+float3(0.0,0.0,  d))-HexGrid(p+float3(0.0,0.0, -d)) ));
			}
			
			float iq_rand( float p )
			{
				return frac(sin(p)*43758.5453);
			}
			
			float Rings( float3 pos )
			{
							float pi = 3.14159;
							float2 wpos = pos.xz;
							float stride = _RingSrtide;
							float strine_half = stride * 0.5;
							float thickness = 1.0 - (_RingThicknessMin + length(_Spectra)*(_RingThicknessMax-_RingThicknessMin));
							float distance = abs(length(wpos) - _Time.y*0.1);
							float fra = _gl_mod(distance, stride);
							float cycle = floor((distance)/stride);
							float c = strine_half - abs(fra-strine_half) - strine_half*thickness;
							c = max(c * (1.0/(strine_half*thickness)), 0.0);
							float rs = iq_rand(cycle*cycle);
							float r = iq_rand(cycle) + _Time.y*(_RingSpeedMin+(_RingSpeedMax-_RingSpeedMin)*rs);
							float angle = atan2(wpos.y, wpos.x) / pi *0.5 + 0.5; // 0.0-1.0
							float a = 1.0-_gl_mod(angle + r, 1.0);
							a = max(a-0.7, 0.0) * c;
							return a;
			}
			
			float Grid( float3 pos )
			{
							float grid_size = 0.4;
							float line_thickness = 0.015;
							float2 m = _gl_mod(abs(pos.xz*sign(pos.xz)), grid_size);
							float s = 0.0;
							if(m.x-line_thickness < 0.0 || m.y-line_thickness < 0.0) {
								return 1.0;
							}
							return 0.0;
			}
			
			float Circle( float3 pos )
			{
						float o_radius = 5.0;
							float i_radius = 4.0;
							float d = length(pos.xz);
							float c = max(o_radius-(o_radius-_gl_mod(d-_Time.y*1.5, o_radius))-i_radius, 0.0);
							return c;
			}
			
			float3 surf43( float4 screenPos , float3 worldPos , float showGrid )
			{
				float2 coord = (screenPos.xy / screenPos.w);
				float3 center = worldPos - _Center;
				float trails = Rings(center);
				float grid_d = showGrid==1.0?HexGrid(center):0;
				float grid = grid_d > 0.0 ? 1.0 : 0.0;
				float3 n = GuessNormal(center);
				n = mul(UNITY_MATRIX_VP, float4(n,0.0)).xyz;
				float circle = Circle(center);
				float3 Emission = float3(0.0,0.0,0.0);
				Emission += trails * (0.5 + _Spectra * _RingEmission);
				//o.Albedo += _GridColor * grid * 0.1;
				Emission += _GridColor * (grid * circle) * _GridEmission;
				const float blur_radius = 0.005;
				float2 blur_coords[9] = {
				    float2( 0.000,  0.000),
				    float2( 0.1080925165271518,  -0.9546740999616308)*blur_radius,
				    float2(-0.4753686437884934,  -0.8417212473681748)*blur_radius,
				    float2( 0.7242715177221273,  -0.6574584801064549)*blur_radius,
				    float2(-0.023355087558461607, 0.7964400038854089)*blur_radius,
				    float2(-0.8308210026544296,  -0.7015103725420933)*blur_radius,
				    float2( 0.3243705688309195,   0.2577797517167695)*blur_radius,
				    float2( 0.31851240326305463, -0.2220789454739755)*blur_radius,
				    float2(-0.36307729185097637, -0.7307245945773899)*blur_radius
				};
				float depth = 1.0;
				depth = tex2D(_ReflectionDepthTex, coord).r;
				for(int i=1; i<9; ++i) {
				    depth = min(depth, tex2D(_ReflectionDepthTex, coord+blur_coords[i]).r);
				}
				float4 H = float4((coord.x) * 2 - 1, (coord.y) * 2 - 1, depth, 1.0);
				float4 D = mul(_ViewProjectInverse, H);
				float3 refpos = D.xyz / D.w;
				float fade_by_depth = 1.0;
				fade_by_depth = max(1.0-abs(refpos.y)*0.3, 0.0);
				float3 refcolor = 0.0;
				float g = saturate((grid_d+0.02)*50.0);
				coord += n.xz * (g>0.0 && g<1.0 ? 1.0 : 0.0) * 0.02;
				for(int i=0; i<9; ++i) {
				    refcolor += tex2D(_ReflectionTex, coord+blur_coords[i]*((1.0-fade_by_depth)*0.75+0.25)).rgb * 0.1111;
				    //refcolor += tex2D(_ReflectionTex, coord+blur_coords[i]).rgb * 0.1111;
				}
				Emission += refcolor * _ReflectionStrength * fade_by_depth * (1.0-grid*0.9);
				return Emission;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord1 = v.texcoord1;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 WorldNormal = normalize( IN.tSpace0.xyz );
				float3 WorldTangent = IN.tSpace1.xyz;
				float3 WorldBiTangent = IN.tSpace2.xyz;
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				#if SHADER_HINT_NICE_QUALITY
					WorldViewDirection = SafeNormalize( WorldViewDirection );
				#endif

				float4 ase_screenPosNorm = ScreenPos / ScreenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 screenPos43 = ase_screenPosNorm;
				float3 worldPos43 = WorldPosition;
				#ifdef _SHOWGRID_ON
				float staticSwitch67 = 1.0;
				#else
				float staticSwitch67 = 0.0;
				#endif
				float showGrid43 = staticSwitch67;
				float3 localsurf43 = surf43( screenPos43 , worldPos43 , showGrid43 );
				
				float3 Albedo = _BaseColor.rgb;
				float3 Normal = float3(0, 0, 1);
				float3 Emission = localsurf43;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = 0.5;
				float Occlusion = 1;
				float Alpha = 1.0;
				float AlphaClipThreshold = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					inputData.normalWS = normalize(TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal )));
				#else
					#if !SHADER_HINT_NICE_QUALITY
						inputData.normalWS = WorldNormal;
					#else
						inputData.normalWS = normalize( WorldNormal );
					#endif
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				
				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Spectra;
			float4 _BaseColor;
			float3 _Center;
			float3 _GridColor;
			float _RingSpeedMin;
			float _ReflectionStrength;
			float _GridEmission;
			float _RingThicknessMax;
			float _RingThicknessMin;
			float _RingSpeedMax;
			float _RingSrtide;
			float _RingEmission;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _ReflectionDepthTex;
			sampler2D _ReflectionTex;
			float4x4 _ViewProjectInverse;


			float Hex( float2 p , float2 h )
			{
				float2 q = abs(p);
							return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
			}
			
			float HexGrid( float3 p )
			{
						float scale = 1.2;
							float2 grid = float2(0.692, 0.4) * scale;
							float radius = 0.22 * scale;
							float2 p1 = _gl_mod(p.xz, grid) - grid*0.5;
							float c1 = Hex(p1, radius);
							float2 p2 = _gl_mod(p.xz+grid*0.5, grid) - grid*0.5;
							float c2 = Hex(p2, radius);
							return min(c1, c2);
			}
			
			float3 GuessNormal( float3 p )
			{
							const float d = 0.01;
							return normalize( float3(
								HexGrid(p+float3(  d,0.0,0.0))-HexGrid(p+float3( -d,0.0,0.0)),
								HexGrid(p+float3(0.0,  d,0.0))-HexGrid(p+float3(0.0, -d,0.0)),
								HexGrid(p+float3(0.0,0.0,  d))-HexGrid(p+float3(0.0,0.0, -d)) ));
			}
			
			float iq_rand( float p )
			{
				return frac(sin(p)*43758.5453);
			}
			
			float Rings( float3 pos )
			{
							float pi = 3.14159;
							float2 wpos = pos.xz;
							float stride = _RingSrtide;
							float strine_half = stride * 0.5;
							float thickness = 1.0 - (_RingThicknessMin + length(_Spectra)*(_RingThicknessMax-_RingThicknessMin));
							float distance = abs(length(wpos) - _Time.y*0.1);
							float fra = _gl_mod(distance, stride);
							float cycle = floor((distance)/stride);
							float c = strine_half - abs(fra-strine_half) - strine_half*thickness;
							c = max(c * (1.0/(strine_half*thickness)), 0.0);
							float rs = iq_rand(cycle*cycle);
							float r = iq_rand(cycle) + _Time.y*(_RingSpeedMin+(_RingSpeedMax-_RingSpeedMin)*rs);
							float angle = atan2(wpos.y, wpos.x) / pi *0.5 + 0.5; // 0.0-1.0
							float a = 1.0-_gl_mod(angle + r, 1.0);
							a = max(a-0.7, 0.0) * c;
							return a;
			}
			
			float Grid( float3 pos )
			{
							float grid_size = 0.4;
							float line_thickness = 0.015;
							float2 m = _gl_mod(abs(pos.xz*sign(pos.xz)), grid_size);
							float s = 0.0;
							if(m.x-line_thickness < 0.0 || m.y-line_thickness < 0.0) {
								return 1.0;
							}
							return 0.0;
			}
			
			float Circle( float3 pos )
			{
						float o_radius = 5.0;
							float i_radius = 4.0;
							float d = length(pos.xz);
							float c = max(o_radius-(o_radius-_gl_mod(d-_Time.y*1.5, o_radius))-i_radius, 0.0);
							return c;
			}
			

			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1.0;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Spectra;
			float4 _BaseColor;
			float3 _Center;
			float3 _GridColor;
			float _RingSpeedMin;
			float _ReflectionStrength;
			float _GridEmission;
			float _RingThicknessMax;
			float _RingThicknessMin;
			float _RingSpeedMax;
			float _RingSrtide;
			float _RingEmission;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _ReflectionDepthTex;
			sampler2D _ReflectionTex;
			float4x4 _ViewProjectInverse;


			float Hex( float2 p , float2 h )
			{
				float2 q = abs(p);
							return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
			}
			
			float HexGrid( float3 p )
			{
						float scale = 1.2;
							float2 grid = float2(0.692, 0.4) * scale;
							float radius = 0.22 * scale;
							float2 p1 = _gl_mod(p.xz, grid) - grid*0.5;
							float c1 = Hex(p1, radius);
							float2 p2 = _gl_mod(p.xz+grid*0.5, grid) - grid*0.5;
							float c2 = Hex(p2, radius);
							return min(c1, c2);
			}
			
			float3 GuessNormal( float3 p )
			{
							const float d = 0.01;
							return normalize( float3(
								HexGrid(p+float3(  d,0.0,0.0))-HexGrid(p+float3( -d,0.0,0.0)),
								HexGrid(p+float3(0.0,  d,0.0))-HexGrid(p+float3(0.0, -d,0.0)),
								HexGrid(p+float3(0.0,0.0,  d))-HexGrid(p+float3(0.0,0.0, -d)) ));
			}
			
			float iq_rand( float p )
			{
				return frac(sin(p)*43758.5453);
			}
			
			float Rings( float3 pos )
			{
							float pi = 3.14159;
							float2 wpos = pos.xz;
							float stride = _RingSrtide;
							float strine_half = stride * 0.5;
							float thickness = 1.0 - (_RingThicknessMin + length(_Spectra)*(_RingThicknessMax-_RingThicknessMin));
							float distance = abs(length(wpos) - _Time.y*0.1);
							float fra = _gl_mod(distance, stride);
							float cycle = floor((distance)/stride);
							float c = strine_half - abs(fra-strine_half) - strine_half*thickness;
							c = max(c * (1.0/(strine_half*thickness)), 0.0);
							float rs = iq_rand(cycle*cycle);
							float r = iq_rand(cycle) + _Time.y*(_RingSpeedMin+(_RingSpeedMax-_RingSpeedMin)*rs);
							float angle = atan2(wpos.y, wpos.x) / pi *0.5 + 0.5; // 0.0-1.0
							float a = 1.0-_gl_mod(angle + r, 1.0);
							a = max(a-0.7, 0.0) * c;
							return a;
			}
			
			float Grid( float3 pos )
			{
							float grid_size = 0.4;
							float line_thickness = 0.015;
							float2 m = _gl_mod(abs(pos.xz*sign(pos.xz)), grid_size);
							float s = 0.0;
							if(m.x-line_thickness < 0.0 || m.y-line_thickness < 0.0) {
								return 1.0;
							}
							return 0.0;
			}
			
			float Circle( float3 pos )
			{
						float o_radius = 5.0;
							float i_radius = 4.0;
							float d = length(pos.xz);
							float c = max(o_radius-(o_radius-_gl_mod(d-_Time.y*1.5, o_radius))-i_radius, 0.0);
							return c;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1.0;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _SHOWGRID_ON


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Spectra;
			float4 _BaseColor;
			float3 _Center;
			float3 _GridColor;
			float _RingSpeedMin;
			float _ReflectionStrength;
			float _GridEmission;
			float _RingThicknessMax;
			float _RingThicknessMin;
			float _RingSpeedMax;
			float _RingSrtide;
			float _RingEmission;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _ReflectionDepthTex;
			sampler2D _ReflectionTex;
			float4x4 _ViewProjectInverse;


			float Hex( float2 p , float2 h )
			{
				float2 q = abs(p);
							return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
			}
			
			float HexGrid( float3 p )
			{
						float scale = 1.2;
							float2 grid = float2(0.692, 0.4) * scale;
							float radius = 0.22 * scale;
							float2 p1 = _gl_mod(p.xz, grid) - grid*0.5;
							float c1 = Hex(p1, radius);
							float2 p2 = _gl_mod(p.xz+grid*0.5, grid) - grid*0.5;
							float c2 = Hex(p2, radius);
							return min(c1, c2);
			}
			
			float3 GuessNormal( float3 p )
			{
							const float d = 0.01;
							return normalize( float3(
								HexGrid(p+float3(  d,0.0,0.0))-HexGrid(p+float3( -d,0.0,0.0)),
								HexGrid(p+float3(0.0,  d,0.0))-HexGrid(p+float3(0.0, -d,0.0)),
								HexGrid(p+float3(0.0,0.0,  d))-HexGrid(p+float3(0.0,0.0, -d)) ));
			}
			
			float iq_rand( float p )
			{
				return frac(sin(p)*43758.5453);
			}
			
			float Rings( float3 pos )
			{
							float pi = 3.14159;
							float2 wpos = pos.xz;
							float stride = _RingSrtide;
							float strine_half = stride * 0.5;
							float thickness = 1.0 - (_RingThicknessMin + length(_Spectra)*(_RingThicknessMax-_RingThicknessMin));
							float distance = abs(length(wpos) - _Time.y*0.1);
							float fra = _gl_mod(distance, stride);
							float cycle = floor((distance)/stride);
							float c = strine_half - abs(fra-strine_half) - strine_half*thickness;
							c = max(c * (1.0/(strine_half*thickness)), 0.0);
							float rs = iq_rand(cycle*cycle);
							float r = iq_rand(cycle) + _Time.y*(_RingSpeedMin+(_RingSpeedMax-_RingSpeedMin)*rs);
							float angle = atan2(wpos.y, wpos.x) / pi *0.5 + 0.5; // 0.0-1.0
							float a = 1.0-_gl_mod(angle + r, 1.0);
							a = max(a-0.7, 0.0) * c;
							return a;
			}
			
			float Grid( float3 pos )
			{
							float grid_size = 0.4;
							float line_thickness = 0.015;
							float2 m = _gl_mod(abs(pos.xz*sign(pos.xz)), grid_size);
							float s = 0.0;
							if(m.x-line_thickness < 0.0 || m.y-line_thickness < 0.0) {
								return 1.0;
							}
							return 0.0;
			}
			
			float Circle( float3 pos )
			{
						float o_radius = 5.0;
							float i_radius = 4.0;
							float d = length(pos.xz);
							float c = max(o_radius-(o_radius-_gl_mod(d-_Time.y*1.5, o_radius))-i_radius, 0.0);
							return c;
			}
			
			float3 surf43( float4 screenPos , float3 worldPos , float showGrid )
			{
				float2 coord = (screenPos.xy / screenPos.w);
				float3 center = worldPos - _Center;
				float trails = Rings(center);
				float grid_d = showGrid==1.0?HexGrid(center):0;
				float grid = grid_d > 0.0 ? 1.0 : 0.0;
				float3 n = GuessNormal(center);
				n = mul(UNITY_MATRIX_VP, float4(n,0.0)).xyz;
				float circle = Circle(center);
				float3 Emission = float3(0.0,0.0,0.0);
				Emission += trails * (0.5 + _Spectra * _RingEmission);
				//o.Albedo += _GridColor * grid * 0.1;
				Emission += _GridColor * (grid * circle) * _GridEmission;
				const float blur_radius = 0.005;
				float2 blur_coords[9] = {
				    float2( 0.000,  0.000),
				    float2( 0.1080925165271518,  -0.9546740999616308)*blur_radius,
				    float2(-0.4753686437884934,  -0.8417212473681748)*blur_radius,
				    float2( 0.7242715177221273,  -0.6574584801064549)*blur_radius,
				    float2(-0.023355087558461607, 0.7964400038854089)*blur_radius,
				    float2(-0.8308210026544296,  -0.7015103725420933)*blur_radius,
				    float2( 0.3243705688309195,   0.2577797517167695)*blur_radius,
				    float2( 0.31851240326305463, -0.2220789454739755)*blur_radius,
				    float2(-0.36307729185097637, -0.7307245945773899)*blur_radius
				};
				float depth = 1.0;
				depth = tex2D(_ReflectionDepthTex, coord).r;
				for(int i=1; i<9; ++i) {
				    depth = min(depth, tex2D(_ReflectionDepthTex, coord+blur_coords[i]).r);
				}
				float4 H = float4((coord.x) * 2 - 1, (coord.y) * 2 - 1, depth, 1.0);
				float4 D = mul(_ViewProjectInverse, H);
				float3 refpos = D.xyz / D.w;
				float fade_by_depth = 1.0;
				fade_by_depth = max(1.0-abs(refpos.y)*0.3, 0.0);
				float3 refcolor = 0.0;
				float g = saturate((grid_d+0.02)*50.0);
				coord += n.xz * (g>0.0 && g<1.0 ? 1.0 : 0.0) * 0.02;
				for(int i=0; i<9; ++i) {
				    refcolor += tex2D(_ReflectionTex, coord+blur_coords[i]*((1.0-fade_by_depth)*0.75+0.25)).rgb * 0.1111;
				    //refcolor += tex2D(_ReflectionTex, coord+blur_coords[i]).rgb * 0.1111;
				}
				Emission += refcolor * _ReflectionStrength * fade_by_depth * (1.0-grid*0.9);
				return Emission;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 screenPos = IN.ase_texcoord2;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 screenPos43 = ase_screenPosNorm;
				float3 worldPos43 = WorldPosition;
				#ifdef _SHOWGRID_ON
				float staticSwitch67 = 1.0;
				#else
				float staticSwitch67 = 0.0;
				#endif
				float showGrid43 = staticSwitch67;
				float3 localsurf43 = surf43( screenPos43 , worldPos43 , showGrid43 );
				
				
				float3 Albedo = _BaseColor.rgb;
				float3 Emission = localsurf43;
				float Alpha = 1.0;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = Albedo;
				metaInput.Emission = Emission;
				
				return MetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend One Zero , One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _EMISSION
			#define ASE_SRP_VERSION 999999

			#pragma enable_d3d11_debug_symbols
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			

			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Spectra;
			float4 _BaseColor;
			float3 _Center;
			float3 _GridColor;
			float _RingSpeedMin;
			float _ReflectionStrength;
			float _GridEmission;
			float _RingThicknessMax;
			float _RingThicknessMin;
			float _RingSpeedMax;
			float _RingSrtide;
			float _RingEmission;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _ReflectionDepthTex;
			sampler2D _ReflectionTex;
			float4x4 _ViewProjectInverse;


			float Hex( float2 p , float2 h )
			{
				float2 q = abs(p);
							return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
			}
			
			float HexGrid( float3 p )
			{
						float scale = 1.2;
							float2 grid = float2(0.692, 0.4) * scale;
							float radius = 0.22 * scale;
							float2 p1 = _gl_mod(p.xz, grid) - grid*0.5;
							float c1 = Hex(p1, radius);
							float2 p2 = _gl_mod(p.xz+grid*0.5, grid) - grid*0.5;
							float c2 = Hex(p2, radius);
							return min(c1, c2);
			}
			
			float3 GuessNormal( float3 p )
			{
							const float d = 0.01;
							return normalize( float3(
								HexGrid(p+float3(  d,0.0,0.0))-HexGrid(p+float3( -d,0.0,0.0)),
								HexGrid(p+float3(0.0,  d,0.0))-HexGrid(p+float3(0.0, -d,0.0)),
								HexGrid(p+float3(0.0,0.0,  d))-HexGrid(p+float3(0.0,0.0, -d)) ));
			}
			
			float iq_rand( float p )
			{
				return frac(sin(p)*43758.5453);
			}
			
			float Rings( float3 pos )
			{
							float pi = 3.14159;
							float2 wpos = pos.xz;
							float stride = _RingSrtide;
							float strine_half = stride * 0.5;
							float thickness = 1.0 - (_RingThicknessMin + length(_Spectra)*(_RingThicknessMax-_RingThicknessMin));
							float distance = abs(length(wpos) - _Time.y*0.1);
							float fra = _gl_mod(distance, stride);
							float cycle = floor((distance)/stride);
							float c = strine_half - abs(fra-strine_half) - strine_half*thickness;
							c = max(c * (1.0/(strine_half*thickness)), 0.0);
							float rs = iq_rand(cycle*cycle);
							float r = iq_rand(cycle) + _Time.y*(_RingSpeedMin+(_RingSpeedMax-_RingSpeedMin)*rs);
							float angle = atan2(wpos.y, wpos.x) / pi *0.5 + 0.5; // 0.0-1.0
							float a = 1.0-_gl_mod(angle + r, 1.0);
							a = max(a-0.7, 0.0) * c;
							return a;
			}
			
			float Grid( float3 pos )
			{
							float grid_size = 0.4;
							float line_thickness = 0.015;
							float2 m = _gl_mod(abs(pos.xz*sign(pos.xz)), grid_size);
							float s = 0.0;
							if(m.x-line_thickness < 0.0 || m.y-line_thickness < 0.0) {
								return 1.0;
							}
							return 0.0;
			}
			
			float Circle( float3 pos )
			{
						float o_radius = 5.0;
							float i_radius = 4.0;
							float d = length(pos.xz);
							float c = max(o_radius-(o_radius-_gl_mod(d-_Time.y*1.5, o_radius))-i_radius, 0.0);
							return c;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				
				float3 Albedo = _BaseColor.rgb;
				float Alpha = 1.0;
				float AlphaClipThreshold = 0.5;

				half4 color = half4( Albedo, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}
		
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18100
1971;42;1780;938;1984.611;324.0699;1.460835;True;False
Node;AmplifyShaderEditor.TexturePropertyNode;46;-957.3352,-299.5243;Inherit;True;Property;_ReflectionDepthTex;ReflectionDepthTex;12;1;[HideInInspector];Create;True;0;0;True;0;False;None;None;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.StaticSwitch;67;-509.1687,529.0575;Inherit;False;Property;_ShowGrid;Show Grid;14;0;Create;True;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;44;-597.2993,144.6635;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;38;-1791.571,691.7924;Inherit;False;float2 q = abs(p)@$			return max(q.x-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x)@;1;False;2;True;p;FLOAT2;0,0;In;;Inherit;False;True;h;FLOAT2;0,0;In;;Inherit;False;Hex;False;True;0;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-700.1408,593.98;Inherit;False;Constant;_Float1;Float 1;16;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;8;-964,-95;Inherit;True;Property;_ReflectionTex;ReflectionTex;0;0;Create;True;0;0;True;0;False;None;None;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-939.3003,721.5313;Inherit;False;Property;_RingEmission;RingEmission;3;0;Create;True;0;0;True;0;False;10;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;23;-1796.541,308.6075;Inherit;False;return frac(sin(p)*43758.5453)@;1;False;1;True;p;FLOAT;0;In;;Inherit;False;iq_rand;False;True;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;37;-1798.767,604.7485;Inherit;False;		float o_radius = 5.0@$			float i_radius = 4.0@$			float d = length(pos.xz)@$			float c = max(o_radius-(o_radius-_gl_mod(d-_Time.y*1.5, o_radius))-i_radius, 0.0)@$			return c@;1;False;1;True;pos;FLOAT3;0,0,0;In;;Inherit;False;Circle;False;True;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-930,472;Inherit;False;Property;_RingSrtide;RingSrtide;6;0;Create;True;0;0;True;0;False;0.2;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-946.0459,881.1755;Inherit;False;Property;_RingSpeedMax;RingSpeedMax;8;0;Create;True;0;0;True;0;False;0.5;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;36;-1796.21,520.3896;Inherit;False;			float grid_size = 0.4@$			float line_thickness = 0.015@$$			float2 m = _gl_mod(abs(pos.xz*sign(pos.xz)), grid_size)@$			float s = 0.0@$			if(m.x-line_thickness < 0.0 || m.y-line_thickness < 0.0) {$				return 1.0@$			}$			return 0.0@;1;False;1;True;pos;FLOAT3;0,0,0;In;;Inherit;False;Grid;False;True;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;45;-611.5955,337.2613;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;62;-301.671,-160.9652;Inherit;False;Property;_BaseColor;Base Color;13;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;14;-940.4245,554.0177;Inherit;False;Property;_RingThicknessMin;RingThicknessMin;5;0;Create;True;0;0;True;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;43;-362.2993,178.6635;Inherit;False;float2 coord = (screenPos.xy / screenPos.w)@$$float3 center = worldPos - _Center@$float trails = Rings(center)@$float grid_d = showGrid==1.0?HexGrid(center):0@$float grid = grid_d > 0.0 ? 1.0 : 0.0@$float3 n = GuessNormal(center)@$n = mul(UNITY_MATRIX_VP, float4(n,0.0)).xyz@$float circle = Circle(center)@$$float3 Emission = float3(0.0,0.0,0.0)@$Emission += trails * (0.5 + _Spectra * _RingEmission)@$//o.Albedo += _GridColor * grid * 0.1@$Emission += _GridColor * (grid * circle) * _GridEmission@$$const float blur_radius = 0.005@$float2 blur_coords[9] = {$    float2( 0.000,  0.000),$    float2( 0.1080925165271518,  -0.9546740999616308)*blur_radius,$    float2(-0.4753686437884934,  -0.8417212473681748)*blur_radius,$    float2( 0.7242715177221273,  -0.6574584801064549)*blur_radius,$    float2(-0.023355087558461607, 0.7964400038854089)*blur_radius,$    float2(-0.8308210026544296,  -0.7015103725420933)*blur_radius,$    float2( 0.3243705688309195,   0.2577797517167695)*blur_radius,$    float2( 0.31851240326305463, -0.2220789454739755)*blur_radius,$    float2(-0.36307729185097637, -0.7307245945773899)*blur_radius$}@$float depth = 1.0@$depth = tex2D(_ReflectionDepthTex, coord).r@$for(int i=1@ i<9@ ++i) {$    depth = min(depth, tex2D(_ReflectionDepthTex, coord+blur_coords[i]).r)@$}$$float4 H = float4((coord.x) * 2 - 1, (coord.y) * 2 - 1, depth, 1.0)@$float4 D = mul(_ViewProjectInverse, H)@$float3 refpos = D.xyz / D.w@$$float fade_by_depth = 1.0@$fade_by_depth = max(1.0-abs(refpos.y)*0.3, 0.0)@$float3 refcolor = 0.0@$$float g = saturate((grid_d+0.02)*50.0)@$coord += n.xz * (g>0.0 && g<1.0 ? 1.0 : 0.0) * 0.02@$for(int i=0@ i<9@ ++i) {$    refcolor += tex2D(_ReflectionTex, coord+blur_coords[i]*((1.0-fade_by_depth)*0.75+0.25)).rgb * 0.1111@$    //refcolor += tex2D(_ReflectionTex, coord+blur_coords[i]).rgb * 0.1111@$}$$Emission += refcolor * _ReflectionStrength * fade_by_depth * (1.0-grid*0.9)@$return Emission@;3;False;3;True;screenPos;FLOAT4;0,0,0,0;In;;Inherit;False;True;worldPos;FLOAT3;0,0,0;In;;Inherit;False;True;showGrid;FLOAT;1;In;;Inherit;False;surf;True;False;4;35;39;41;37;3;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-693.1409,500.7582;Inherit;False;Constant;_Float0;Float 0;16;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;41;-1799.571,894.7924;Inherit;False;			const float d = 0.01@$			return normalize( float3($				HexGrid(p+float3(  d,0.0,0.0))-HexGrid(p+float3( -d,0.0,0.0)),$				HexGrid(p+float3(0.0,  d,0.0))-HexGrid(p+float3(0.0, -d,0.0)),$				HexGrid(p+float3(0.0,0.0,  d))-HexGrid(p+float3(0.0,0.0, -d)) ))@;3;False;1;True;p;FLOAT3;0,0,0;In;;Inherit;False;GuessNormal;False;True;1;39;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector4Node;11;-926,132;Inherit;False;Property;_Spectra;Spectra;2;0;Create;True;0;0;True;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;15;-941.5488,636.0883;Inherit;False;Property;_RingThicknessMax;RingThicknessMax;4;0;Create;True;0;0;True;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;39;-1796.571,804.7924;Inherit;False;		float scale = 1.2@$			float2 grid = float2(0.692, 0.4) * scale@$			float radius = 0.22 * scale@$$			float2 p1 = _gl_mod(p.xz, grid) - grid*0.5@$			float c1 = Hex(p1, radius)@$$			float2 p2 = _gl_mod(p.xz+grid*0.5, grid) - grid*0.5@$			float c2 = Hex(p2, radius)@$			return min(c1, c2)@;1;False;1;True;p;FLOAT3;0,0,0;In;;Inherit;False;HexGrid;False;True;1;38;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;35;-1799.653,405.8653;Inherit;False;			float pi = 3.14159@$			float2 wpos = pos.xz@$$			float stride = _RingSrtide@$			float strine_half = stride * 0.5@$			float thickness = 1.0 - (_RingThicknessMin + length(_Spectra)*(_RingThicknessMax-_RingThicknessMin))@$			float distance = abs(length(wpos) - _Time.y*0.1)@$			float fra = _gl_mod(distance, stride)@$			float cycle = floor((distance)/stride)@$$			float c = strine_half - abs(fra-strine_half) - strine_half*thickness@$			c = max(c * (1.0/(strine_half*thickness)), 0.0)@$$			float rs = iq_rand(cycle*cycle)@$			float r = iq_rand(cycle) + _Time.y*(_RingSpeedMin+(_RingSpeedMax-_RingSpeedMin)*rs)@$$			float angle = atan2(wpos.y, wpos.x) / pi *0.5 + 0.5@ // 0.0-1.0$			float a = 1.0-_gl_mod(angle + r, 1.0)@$			a = max(a-0.7, 0.0) * c@$			return a@;1;False;1;True;pos;FLOAT3;0,0,0;In;;Inherit;False;Rings;False;True;1;23;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;9;-635,-61;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;12;-928,320;Inherit;False;Property;_Center;Center;1;0;Create;True;0;0;True;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;20;-942.6733,967.7429;Inherit;False;Property;_GridColor;GridColor;11;0;Create;True;0;0;True;0;False;0.2,0.3,0.5;0.2,0.3,0.5;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;47;-178.6587,279.7032;Inherit;False;Constant;_alpha;alpha;13;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-943.6755,1220.822;Inherit;False;Property;_ReflectionStrength;ReflectionStrength;10;0;Create;True;0;0;True;0;False;0.2;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-941.2709,1133.422;Inherit;False;Property;_GridEmission;GridEmission;9;0;Create;True;0;0;True;0;False;8;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-942.673,799.1051;Inherit;False;Property;_RingSpeedMin;RingSpeedMin ;7;0;Create;True;0;0;True;0;False;0.2;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Matrix4X4Node;54;-1219.672,126.0402;Inherit;False;Global;_ViewProjectInverse;ViewProjectInverse;13;0;Create;True;0;0;True;0;False;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;True;False;False;False;False;0;False;-1;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;True;True;True;True;True;0;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;True;2;False;-1;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;Custom/Visualizer;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;16;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;33;Workflow;1;Surface;0;  Refraction Model;0;  Blend;0;Two Sided;1;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;1;Built-in Fog;1;Meta Pass;1;Override Baked GI;0;Extra Pre Pass;0;DOTS Instancing;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;True;True;True;True;False;;0
WireConnection;67;1;65;0
WireConnection;67;0;66;0
WireConnection;43;0;44;0
WireConnection;43;1;45;0
WireConnection;43;2;67;0
WireConnection;9;0;8;0
WireConnection;2;0;62;0
WireConnection;2;2;43;0
WireConnection;2;6;47;0
ASEEND*/
//CHKSM=55A50D904F536966CDDFAA5C778C0F44FC08DC65