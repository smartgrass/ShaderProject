Shader "Custom/Scanner"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _CameraDepthTexture ("_CameraDepthTexture", 2D) ="white" {}
        
        _ScanColor ("_ScanColor", Color) = (1,1,1,1)
        _ScanCenter ("_ScanCenter", float) = 0.5
        _ScanDistance ("_ScanDistance", float) = 0.5
        _ScanRange ("_ScanRange", float) = 0.5
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _ScanColor;
            
            float4x4 _FrustumCornersRay; //??
            float3 _ScanCenter;
            
            float _ScanDistance;
            float _ScanRange;
                
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 depth_uv : TEXCOORD1;
                float4 interpolatedRay : TEXCOORD2;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                o.depth_uv = v.texcoord.xy;

                //当前顶点是四边形的哪个顶点：0-bl, 1-br, 2-tr, 3-tl
                int index = 0;
                if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
                    index = 0;
                else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5)
                    index = 1;
                else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
                    index = 2;
                else
                    index = 3;

                o.interpolatedRay = _FrustumCornersRay[index];

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 finalColor = tex2D(_MainTex, i.uv);
                //view space depth
                float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.depth_uv));
                //linearDepth * i.interpolatedRay.xyz：当前像素相对摄像机的偏移
                float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

                float distanceFromCenter = distance(worldPos, _ScanCenter);
                //z = far plane
                if (distanceFromCenter < _ScanDistance && linearDepth < _ProjectionParams.z)
                {
                    fixed scanPercent = 1 - (_ScanDistance - distanceFromCenter) / _ScanRange;
                    finalColor = lerp(finalColor, _ScanColor, scanPercent);
                }
                return finalColor;
            }
            ENDCG
        }
    }
}