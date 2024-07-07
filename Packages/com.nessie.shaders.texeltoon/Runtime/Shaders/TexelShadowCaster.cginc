#if !defined(TEXEL_SHADOWCASTER_INCLUDED)
#define TEXEL_SHADOWCASTER_INCLUDED

#include "UnityCG.cginc"
#include "TexelLightingInput.cginc"

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
    #if defined(_ALPHATEST_ON)
        float2 uv = input.uv; 
        float4 ddxy = float4(ddx(uv), ddy(uv));
        fixed4 albedo = GetAlbedo(uv, ddxy);
        clip(albedo.a - _Cutoff + 0.0001);
    #endif

    SHADOW_CASTER_FRAGMENT(input) // Might use input.
}

#endif