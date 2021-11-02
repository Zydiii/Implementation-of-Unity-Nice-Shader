Shader "ShaderCookBook/Animation"
{
    Properties
    {
        _Color ("Default Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SpriteRowNum ("Sprite Row Num", int) = 0
        _SpriteColumnNum ("SPrite Colume Num", int) = 0
        _TexWidth ("Texture Width", float) = 0.0
        _TexHeight ("Texture Height", float) = 0.0
        _Speed ("Speed", float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Lambert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        int _SpriteRowNum, _SpriteColumnNum;
        float _TexWidth, _TexHeight, _Speed;
        float4 _Color;

        struct Input
        {
            float2 uv_MainTex;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            float2 spriteUV = IN.uv_MainTex;
            float eachSpriteWidth = _TexWidth / _SpriteRowNum;
            float eachSpriteHeight = _TexHeight / _SpriteColumnNum;
            float eachSpriteWidthPercentage = eachSpriteWidth / _TexWidth;
            float eachSpriteHeightPercentage = eachSpriteHeight / _TexHeight;

            int index = ceil(fmod(_Time.y * _Speed, _SpriteRowNum));

            float xUV = spriteUV.x;
            xUV += index * eachSpriteWidthPercentage * _SpriteRowNum;
            xUV *= eachSpriteWidthPercentage;

            index = 0;
            float yUV = spriteUV.y;
            yUV += index * eachSpriteHeightPercentage * _SpriteColumnNum;
            yUV *= eachSpriteHeightPercentage;

            spriteUV = float2(xUV, yUV);
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, spriteUV) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
