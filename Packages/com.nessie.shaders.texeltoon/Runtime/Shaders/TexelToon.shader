// v0.4.0

Shader "Nessie/TexelToon/Lit"
{
    Properties
    {
        //[Header(Main Maps)] [Space]
        _MainTex ("Albedo", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1)

        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Glossiness ("Smoothness", Range(0.0, 1.0)) = 0.25
        [NoScaleOffset] _SpecGlossMap ("Smoothness Map", 2D) = "white" {}

        [Gamma] _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        [NoScaleOffset] _MetallicGlossMap ("Metallic Map", 2D) = "white" {}

        _BumpScale("Normal Strength", Float) = 1.0
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}

        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}

        _EmissionColor("Emission", Color) = (0,0,0)
        [NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}

        //[Header(Texel Settings)] [Space]
        [Toggle] _Texel_AA ("Texel Anti-Aliasing (Bilinear Textures)", Float) = 0
        [KeywordEnum(Auto, Manual)] _TexelMode ("Texel Density Mode", Float) = 0
        _TexelDensity ("Texel Density (xy)", Vector) = (64, 64, 0, 0)
        _TexelDensityMultiplier ("Texel Multiplier (xy)", Vector) = (1, 1, 0, 0)

        [NoScaleOffset] _ColorLUT ("Palette LUT", 2D) = "white" {}
        [Toggle] _Dither ("Dithering", Float) = 0

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Int) = 2

        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    CustomEditor "Nessie.Shader.Texel.Editor.TexelToonGUI"

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "VRCFallback" = "Toon"
        }

        CGINCLUDE // Includes for all passes.

        #include "DebugUtils.cginc"

        ENDCG

        Pass
        {
            Name "FORWARD_BASE"
            Tags { "LightMode" = "ForwardBase" }

            //AlphaToMask On
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]

            CGPROGRAM

            #pragma target 3.0

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

            #pragma shader_feature_local _ _TEXEL_AA_ON
            #pragma shader_feature_local _TEXELMODE_AUTO _TEXELMODE_MANUAL
            #pragma shader_feature_local _ _DITHER_ON

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #pragma vertex TexelVert
            #pragma fragment TexelFrag

            #include "TexelLighting.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD_ADD"
            Tags { "LightMode" = "ForwardAdd" }

            //AlphaToMask On
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual
            Cull [_CullMode]

            CGPROGRAM

            #pragma target 3.0

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

            #pragma shader_feature_local _ _TEXEL_AA_ON
            #pragma shader_feature_local _TEXELMODE_AUTO _TEXELMODE_MANUAL
            #pragma shader_feature_local _ _DITHER_ON

            #pragma multi_compile _ VERTEXLIGHT_ON

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex TexelVert
            #pragma fragment TexelFrag

            #include "TexelLighting.cginc"

            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            Cull [_CullMode]

            CGPROGRAM

            #pragma target 3.0

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #pragma vertex TexelVertShadow
            #pragma fragment TexelFragShadow

            #include "TexelShadowCaster.cginc"

            ENDCG
        }

        Pass
        {
            // Temp for Lightmapping and editor visualization.
            Name "META"
            Tags { "LightMode" = "Meta" }

            Cull Off

            CGPROGRAM

            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"

            ENDCG
        }

        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            Cull Off

            CGPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

            #pragma shader_feature_local _ _TEXEL_AA_ON

            #include "UnityCG.cginc"
            #include "TexelLightingInput.cginc"

            struct Attributes
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.pos = UnityObjectToClipPos(input.vertex);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                return output;
            }

            #if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
                #define USE_ALPHA
            #endif

            fixed4 Frag(Varyings input) : SV_Target
            {
                #ifdef USE_ALPHA
                    float2 uv = input.uv;
                    float4 ddxy = float4(ddx(uv), ddy(uv));
                    fixed4 albedo = GetAlbedo(uv, ddxy);
                    #if defined(_ALPHATEST_ON)
                        clip(albedo.a - _Cutoff + 0.0001);
                    #else
                        clip(albedo.a - 0.0001);
                    #endif
                #endif

                return 1;
            }

            ENDCG
        }
    }
}
