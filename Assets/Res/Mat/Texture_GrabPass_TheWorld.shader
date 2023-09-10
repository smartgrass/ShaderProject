// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "MyShader/Texture_GrabPass_TheWorld"
{
    Properties
    {
		_BaseColor("Base Color",Color) = (1.0,1.0,1.0,1.0)
		_MainTex("Main Texture",2D) = "white"{}
		_progres("progres进度",Range(0,1)) =  0.5
		_radius("radius范围",Range(0,1)) =  0.5
		_band("band宽度",Range(0,1)) = 0.1
		_speed("speed",float) =  1
		_power("power",float) =  1
		_waves("waves",int) =  1
		_aspect("_aspect屏幕宽高比",float) =  1
		_changeColor("changeColor",Range(0,1))=1
    }
    SubShader
    {
        Tags{"Queue"="Transparent" "RenderType"="Opaque"}
		GrabPass{"_GrabPassTexture"}
		//GrabPass会将屏幕内容输出到指定纹理
        Pass
        {
			Tags{"LightMode"="Always"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#include "Lighting.cginc"
            #include "UnityCG.cginc"
			#define PI 3.1415926

            struct inputData{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
            };

            struct outputData{
                float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;  //xy:原纹理uv zw:屏幕uv坐标
				float4 pos2 : TEXCOORD1;
            };

			sampler2D _GrabPassTexture;
			sampler2D _MainTex;
			fixed4 _BaseColor;
			float _progres;
			float _band;
			float _radius;
			float _waves;
			float _speed;
			float _power;
			float _aspect;
			float2 centerUV;
			float _changeColor;


			// RGB -> HSV 色彩空间
			float3 FRGB2HSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
				float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;
				return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			//HSV -> RGB
			float3 FHSV2RGB(float3 c)
			{
				float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
				float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
				return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
			}

			//扭曲函数 屏幕
			float2 FCausticTriTwist(float2 pointUv,float2 centerUV,float time)
			{
				float wave_width = _band * _radius;

				//屏幕比例
				float2 dir = (pointUv - centerUV);
				dir.x = dir.x  * _aspect;
				float len = length(dir);

				float current_progress = _progres;
				float current_radius = _radius * current_progress;
				float damp_factor = 1.0; //衰减系数
				if (current_progress > 0.5) {
					damp_factor = (1.0 - current_progress) * 2.0;
				}
				//裁剪系数
				float cut_factor = clamp(wave_width * damp_factor - abs(current_radius - len), 0.0, 1.0);
				float waves_factor = _waves * len / _radius;
				float2 uv_offset = (dir / len) * cos((waves_factor - current_progress * _speed) * 3.14) * _power * cut_factor;

				return float2(pointUv + uv_offset);
			}

            outputData vert(inputData i)
            {
                outputData o;
                o.pos = UnityObjectToClipPos(i.vertex);
				o.pos2 = i.vertex;
				o.uv.xy = i.texcoord.xy;

				fixed4 screenPos = ComputeGrabScreenPos(o.pos); //计算屏幕坐标
				o.uv.zw = screenPos.xy/screenPos.w; //屏幕uv坐标
				return o;
            }

			fixed4 frag(outputData i):SV_TARGET{

				fixed3 albedo =tex2D(_MainTex,i.uv.xy);
				float time = _Time.y;



				//中心UV
				fixed4 centerPos =  ComputeGrabScreenPos(UnityObjectToClipPos(float3(0,0,0)));
				centerUV = centerPos.xy/centerPos.w;

				float2 newUV = FCausticTriTwist(i.uv.zw,centerUV,time);
				fixed3 color = tex2D(_GrabPassTexture,newUV).xyz *_BaseColor *albedo;

				if(_changeColor<0.5){
					return float4(color,1);
				}
				//颜色变化
				float3 hsvColor = FRGB2HSV(color);

				hsvColor.x += lerp(0,0.2,sin( UNITY_TWO_PI * frac(_Time.y *0.5)));
				hsvColor.x = frac(hsvColor.x);
				hsvColor = FHSV2RGB(hsvColor);
				return float4 (hsvColor,1);
            }
            ENDCG
        }
    }
}
