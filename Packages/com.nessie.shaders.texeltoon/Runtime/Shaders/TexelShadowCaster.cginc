#if !defined(TEXEL_SHADOWCASTER_INCLUDED)
#define TEXEL_SHADOWCASTER_INCLUDED

#include "UnityCG.cginc"
#include "TexelLightingInput.cginc"

#if (defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)) && defined(UNITY_USE_DITHER_MASK_FOR_ALPHABLENDED_SHADOWS)
    #define USE_DITHER_MASK 1
#endif

// SHADOW_ONEMINUSREFLECTIVITY(): workaround to get one minus reflectivity based on UNITY_SETUP_BRDF_INPUT
#define SHADOW_JOIN2(a, b) a##b
#define SHADOW_JOIN(a, b) SHADOW_JOIN2(a,b)
#define SHADOW_ONEMINUSREFLECTIVITY SHADOW_JOIN(MetallicSetup, _ShadowGetOneMinusReflectivity)

struct Attributes
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    V2F_SHADOW_CASTER; // Might occupy TEXCOORD0.

    float2 uv : TEXCOORD1;

    UNITY_VERTEX_OUTPUT_STEREO
};

#ifdef USE_DITHER_MASK
    sampler3D _DitherMaskLOD;
#endif

Varyings TexelVertShadow(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    // Since Unity depends on input being called v, we can redefine it to circumvents it.
    #define v input
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(output)
    #undef v
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);

    return output;
}

float4 TexelFragShadow(Varyings input) : SV_TARGET
{
    float2 uv = input.uv;
    float4 ddxy = float4(ddx(uv), ddy(uv));
    fixed4 albedo = GetAlbedo(uv, ddxy);
    half alpha = albedo.a;
    #if defined(_ALPHATEST_ON)
        clip(alpha - _Cutoff - 0.0001);
    #endif

    float4 vpos = input.pos;
    #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
        #if defined(_ALPHAPREMULTIPLY_ON)
            half outModifiedAlpha;
            PreMultiplyAlpha(half3(0, 0, 0), alpha, SHADOW_ONEMINUSREFLECTIVITY(uv), outModifiedAlpha);
            alpha = outModifiedAlpha;
        #endif

        #if defined(USE_DITHER_MASK)
            // Use dither mask for alpha blended shadows, based on pixel position xy
            // and alpha level. Our dither texture is 4x4x16.
            #ifdef LOD_FADE_CROSSFADE
                #define _LOD_FADE_ON_ALPHA
                alpha *= unity_LODFade.y;
            #endif
            half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, alpha * 0.9375)).a;
            clip (alphaRef - 0.01);
        #else
            clip (alpha - _Cutoff - 0.0001);
        #endif
    #endif

    SHADOW_CASTER_FRAGMENT(input) // Might use input.
}

#endif