// v0.4.0

Shader "Nessie/TexelToon/Lit (Outline)"
{
    Properties
    {
        //[Header(Main Maps)] [Space]
        _MainTex ("Albedo", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.25
        [NoScaleOffset] _SpecGlossMap("Smoothness Map", 2D) = "white" {}
        
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        [NoScaleOffset] _MetallicGlossMap("Metallic Map", 2D) = "white" {}
        
        _BumpScale("Normal Strength", Float) = 1.0
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        
        _OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        
        _EmissionColor("Emission", Color) = (0,0,0)
        [NoScaleOffset] _EmissionMap("Emission Map", 2D) = "white" {}
        
        //[Header(Texel Settings)] [Space]
        [Toggle] _Texel_AA ("Texel Anti-Aliasing (Bilinear Textures)", Float) = 0
        [KeywordEnum(Auto, Manual)] _TexelMode ("Texel Density Mode", Float) = 0
        _TexelDensity ("Texel Density (xy)", Vector) = (64, 64, 0, 0)
        _TexelDensityMultiplier ("Texel Multiplier (xy)", Vector) = (1, 1, 0, 0)
        
        [NoScaleOffset] _ColorLUT ("Palette LUT", 2D) = "white" {}
        [Toggle] _Dither ("Dithering", Float) = 0
        
        //[Header(Outline)] [Space]
        _OutlineWidth("Outline Width", Float) = 0.01
        _OutlineColor("Outline Color", Color) = (0,0,0)
        
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 2
        
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
        
        Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWrite]
        Cull [_CullMode]

        CGINCLUDE // Includes for all passes.
        
        #include "DebugUtils.cginc"

        ENDCG
        
        Pass
        {
            Name "FORWARD_BASE"
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma target 3.0

            #pragma shader_feature_local _ _TEXEL_AA_ON
            #pragma shader_feature_local _TEXELMODE_AUTO _TEXELMODE_MANUAL
            #pragma shader_feature_local _ _DITHER_ON

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            
            #pragma vertex TexelVert
            #pragma fragment TexelFrag

            #include "TexelLighting.cginc"

            ENDCG
        }

        Pass
        {
            Name "FORWARD_ADD"
            Tags
            {
                "LightMode" = "ForwardAdd"
            }
            
            Blend One One
            ZWrite Off

            CGPROGRAM

            #pragma target 3.0

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
            Name "OUTLINE"
            Tags { }
            
            Cull Front
            
            CGPROGRAM

            #pragma target 3.0

            #pragma vertex Vert
            #pragma fragment Frag

            #include "UnityCG.cginc"

            struct Varyings
            {
                float4 pos : SV_POSITION;
                
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            float _OutlineWidth;
            
            Varyings Vert(appdata_base input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_OUTPUT(Varyings, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.pos = UnityObjectToClipPos(input.vertex + input.normal * _OutlineWidth);
                
                return output;
            }
            
            half3 _OutlineColor;

            half4 Frag() : SV_TARGET
            {
                return half4(_OutlineColor, 1);
            }
            
            ENDCG
        }

        Pass
        {
            Name "SHADOWCASTER"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM

            #pragma target 3.0
            
            #pragma multi_compile_shadowcaster

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

            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION

            #include "UnityStandardMeta.cginc"
            ENDCG
        }
    }
}
