Shader "Blinn-Phong"
{
    Properties
    {
        _Diffuse ("Texture", 2D) = "white" {}
        _Normal ("Normal", 2D) = "blue" {}
        _Specular ("Specular", 2D) = "black" {}
        _Environment ("Environment", Cube) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            struct vIN
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct vOUT
            {
                float4 pos : SV_POSITION;
                float3x3 tbn : TEXCOORD0;
                float2 uv : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            vOUT vert(vIN v)
            {
                vOUT o;
                // 裁剪空间的位置
                o.pos = UnityObjectToClipPos(v.vertex);
                // 纹理坐标
                o.uv = v.uv;
                // TBN 矩阵
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBitan = cross(worldNormal, worldTangent);
                o.tbn = float3x3(worldTangent, worldBitan, worldNormal);
                // 世界位置
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            sampler2D _Normal;
            sampler2D _Diffuse;
            sampler2D _Specular;
            samplerCUBE _Environment;
            float4 _LightColor0;

            float4 frag(vOUT i) : SV_Target
            {
                // 法向量
                float3 unpackNormal = UnpackNormal(tex2D(_Normal, i.uv));
                float3 nrm = normalize(mul(transpose(i.tbn), unpackNormal));
                // 视线方向
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                // 半向量
                float3 halfVec = normalize(viewDir + _WorldSpaceLightPos0.xyz);

                // 纹理采样
                float4 tex = tex2D(_Diffuse, i.uv);
                float4 specMask = tex2D(_Specular, i.uv);

                // 环境光
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * tex.rgb;

                // 漫反射
                float3 env = texCUBE(_Environment, reflect(-viewDir, nrm)).rgb;
                float3 sceneLight = lerp(_LightColor0, env + _LightColor0 * 0.5, 0.5);
                float diffAmt = max(dot(nrm, _WorldSpaceLightPos0.xyz), 0.0);
                float3 diffCol = sceneLight * diffAmt * tex.rgb;
                
                // 镜面反射
                float specAmt = pow(max(0.0, dot(halfVec, nrm)), 4.0);
                float3 specCol = specMask.rgb * specAmt * sceneLight;

                return float4(ambient + diffCol + specCol, 1.0);
            }
            
            ENDCG
        }
        
        // 多光源
        Pass
        {
            Tags {"LightMode" = "ForwardAdd" "Queue" = "Geometry"}
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdadd

            struct vIN
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct vOUT
            {
                float4 pos : SV_POSITION;
                float3x3 tbn : TEXCOORD0;
                float2 uv : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                LIGHTING_COORDS(5, 6)
            };

            vOUT vert(vIN v)
            {
                vOUT o;
                // 裁剪空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 纹理坐标
                o.uv = v.uv;
                
                // 法向量
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // 切向量
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // 副切线
                float3 worldBitan = cross(worldNormal, worldTangent);
                // TBN
                o.tbn = float3x3(worldTangent, worldBitan, worldNormal);
                
                // 世界坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_VERTEX_TO_FRAGMENT(o); 

                return o;
            }

            sampler2D _Normal;
            sampler2D _Diffuse;
            sampler2D _Specular;
            samplerCUBE _Environment;
            float4 _LightColor0;
            
            float4 frag(vOUT i) : SV_Target
            {
                // 计算基础向量
                float3 unpackNormal = UnpackNormal(tex2D(_Normal, i.uv));
				float3 nrm = normalize(mul(transpose(i.tbn), unpackNormal));
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 toLight = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
                float3 halfVec = normalize(viewDir + toLight);
                float3 env = texCUBE(_Environment, reflect(-viewDir, nrm)).rgb;
                float3 sceneLight = lerp(_LightColor0, env + _LightColor0 * 0.5, 0.5);
                float falloff = LIGHT_ATTENUATION(i);

                // 光照
                float diffAmt = max(dot(nrm, toLight), 0.0) * falloff;
                float specAmt = max(0.0, dot(halfVec, nrm));
                specAmt = pow(specAmt, 4.0) * falloff;

                // 纹理
                float4 tex = tex2D(_Diffuse, i.uv);
                float4 specMask = tex2D(_Specular, i.uv);

                // 反射光
                float3 specCol = specMask.rgb * specAmt;

                // 最终的漫反射和反射光
                float3 finalDiffuse = sceneLight * diffAmt * tex.rgb;
                float3 finalSpec = specCol * sceneLight;
                
                return float4(finalDiffuse + finalSpec, 1.0);
            }
            
            ENDCG
        }
    }
}
