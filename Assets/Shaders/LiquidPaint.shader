Shader "LiquidPaint"
{
	SubShader
	{

//------Common-------------------------------------------------------------------------------------------
	
		CGINCLUDE
		#pragma vertex VSMain
		#pragma fragment PSMain
		
		Texture2D<float4> _BufferA;	
		Texture2D<float4> _BufferB;
		SamplerState _LinearClamp;
		
		int iFrame;
		float4 iMouse;
		float4 iResolution;
		
		void VSMain (inout float4 vertex:POSITION, inout float2 uv:TEXCOORD0)
		{
			vertex = UnityObjectToClipPos(vertex);
		}
		
		ENDCG

//------Buffer A-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
		
			void PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 fragCoord = uv * iResolution.xy;
				fragColor = (distance(iMouse.xy, fragCoord) < 10.0).xxxx;
				fragColor += _BufferA.Sample(_LinearClamp, fragCoord.xy / iResolution.xy);  
			}
			
			ENDCG
		}
		
//------Buffer B-------------------------------------------------------------------------------------------
		
		Pass
		{ 
			CGPROGRAM

			#define Move(U, dir) _BufferB.Load( int3(U + dir, 0) )
			
			void PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 O:SV_TARGET)
			{	
				float2 U = uv * iResolution.xy;
				O = float4(0,0,0,0);
				float s = 0.;
				for (int i=0; i<9; i+= i==3 ? 2 : 1 ) 
				{
					float2 D = float2( i%3-1, i/3-1);
					O +=  Move( U, D ) / length(D);
					s += 1./ length(D);
				}
				O /= s;
				O += _BufferA.Load( int3(U, 0) );    
			}
			
			ENDCG
		}
		
//------Image-------------------------------------------------------------------------------------------

		Pass
		{ 
			CGPROGRAM
			
			float diffuse;
			float specular;

			void calculateLighting(float2 uv)
			{
				float l = length(_BufferB.Sample(_LinearClamp, uv).xyz);
				float dx=ddx(l)*iResolution.x;
				float dy=ddy(l)*iResolution.y;
				
				// Calculating Normal by dx and dy
				float3 N =normalize(float3(dx,dy,100.0));
				
				// Light Direction
				float3 L = normalize(float3(1.0, 1.0, 2.0));
				
				// Calculating Diffuse
				diffuse = max(dot(N, L)  + 1., 0.);
				
				// Calculating Specular
				specular = clamp(dot(reflect(L, N),float3(0, 0, -1)), 0., 1.0);
				
				specular = pow(specular, 12.0);
			}


			void PSMain (float4 vertex:POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 fragCoord = uv * iResolution.xy;
  
				// Normalized pixel coordinates (from 0 to 1)
				calculateLighting(uv);

				// Get Liquid From Buffer B
				float3 liquid = _BufferB.Sample(_LinearClamp, uv).rgb;

				// Normalizing Liquid
				liquid = clamp(liquid,0.,0.5);

				// Cream Color
				float3 color = float3(1.,0.99,0.81);

				float3 finalColor = liquid * color * diffuse + specular;

				fragColor = float4(finalColor, 1.0);
			}
			
			ENDCG
		}

//-------------------------------------------------------------------------------------------
		
	}
}
