Shader "Custom/WaveShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Steepness ("Steepness", Range(0, 1)) = 0.5
        _Wavelength ("Wavelength", Float) = 10
        _Direction ("Direction (2D)", Vector) = (1, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float _Steepness, _Wavelength;
        float2 _Direction;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full vertexData)
        {
            float3 p = vertexData.vertex.xyz;

            float k = 2 * UNITY_PI / _Wavelength;
            float c = sqrt(9.8 / k);
            float2 d = normalize(_Direction);
            float f = k * (dot(d, p.xz) - c * _Time.y);
            float a = _Steepness / k;
            
            p.x += d.x * a * cos(f);
            p.y = a * sin(f);
            p.z += d.y * a * cos(f);

            float3 tangent = float3(
                1 - d.x * d.x * _Steepness * sin(f),
                d.x * _Steepness * cos(f),
                -d.x * d.y * _Steepness * sin(f));
            float3 binormal = float3(
                -d.x * d.y * _Steepness * sin(f),
                d.y * _Steepness * cos(f),
                1 - d.y * d.y * _Steepness * sin(f));
            float3 normal = normalize(cross(binormal, tangent));

			vertexData.normal = normal;
            vertexData.vertex.xyz = p;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
