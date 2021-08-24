Shader "Graph/Point Surface"
{
    Properties
    {
        _Smoothness("Smoothness", Range(0,1)) = 0.5
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        //LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface configureSurface Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        struct Input
        {
            float3 worldPos;
        };

        float _Smoothness;

        void configureSurface(Input input, inout SurfaceOutputStandard surface)
        {
            surface.Albedo.rg = saturate(input.worldPos.xy * 0.5 + 0.5);
            surface.Smoothness = _Smoothness;
        }

        //void surf (Input IN, inout SurfaceOutputStandard o)
        //{

        //}
        ENDCG
    }
    FallBack "Diffuse"
}
