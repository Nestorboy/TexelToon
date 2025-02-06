#ifndef TEXEL_AUTO_LIGHT_INCLUDED
#define TEXEL_AUTO_LIGHT_INCLUDED

#include "AutoLight.cginc"

#ifdef POINT
    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos, linearWorldPos) \
        unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r * shadow;
#endif

//#define SPOT
#ifdef SPOT
    inline fixed TexelSpotCookie(unityShadowCoord4 lightCoord, unityShadowCoord4 linearLightCoord)
    {
        float2 realLightCoord = linearLightCoord.xy / linearLightCoord.w + 0.5;
        return tex2Dgrad(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5, ddx(realLightCoord), ddy(realLightCoord)).w;
    }

    inline fixed TexelSpotAttenuate(unityShadowCoord3 lightCoord, unityShadowCoord3 linearLightCoord)
    {
        float2 realLightCoord = dot(linearLightCoord, linearLightCoord).xx;
        return tex2Dgrad(_LightTextureB0, dot(lightCoord, lightCoord).xx, ddx(realLightCoord), ddy(realLightCoord)).r;
    }

    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
        #define DECLARE_LIGHT_COORD(destName, input, worldPos) unityShadowCoord4 destName = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1))
    #else
        #define DECLARE_LIGHT_COORD(destName, input, worldPos) unityShadowCoord4 destName = input._LightCoord
    #endif

    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos, linearWorldPos) \
        DECLARE_LIGHT_COORD(lightCoord, input, worldPos); \
        DECLARE_LIGHT_COORD(linearLightCoord, input, linearWorldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = (lightCoord.z > 0) * TexelSpotCookie(lightCoord, linearLightCoord) * TexelSpotAttenuate(lightCoord.xyz, linearLightCoord.xyz) * shadow;
#endif

#ifdef DIRECTIONAL
    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos, linearWorldPos) fixed destName = UNITY_SHADOW_ATTENUATION(input, worldPos);
#endif

//#define POINT_COOKIE
#ifdef POINT_COOKIE
    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
        #define DECLARE_LIGHT_COORD(destName, input, worldPos) unityShadowCoord3 destName = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz
    #else
        #define DECLARE_LIGHT_COORD(destName, input, worldPos) unityShadowCoord3 destName = input._LightCoord
    #endif

    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos, linearWorldPos) \
        DECLARE_LIGHT_COORD(lightCoord, input, worldPos); \
        DECLARE_LIGHT_COORD(linearLightCoord, input, linearWorldPos); \
        float2 realLightCoord = dot(linearLightCoord, linearLightCoord).rr; \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        float cookie = texCUBEgrad(_LightTexture0, lightCoord, ddx(linearLightCoord), ddy(linearLightCoord)).w; \
        fixed destName = tex2Dgrad(_LightTextureB0, dot(lightCoord, lightCoord).rr, ddx(realLightCoord), ddy(realLightCoord)).r * cookie * shadow;
#endif

//#define DIRECTIONAL_COOKIE
#ifdef DIRECTIONAL_COOKIE
    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
        #define DECLARE_LIGHT_COORD(destName, input, worldPos) unityShadowCoord2 destName = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy
    #else
        #define DECLARE_LIGHT_COORD(destName, input, worldPos) unityShadowCoord2 destName = input._LightCoord
    #endif

    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos, linearWorldPos) \
        DECLARE_LIGHT_COORD(lightCoord, input, worldPos); \
        DECLARE_LIGHT_COORD(linearLightCoord, input, linearWorldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2Dgrad(_LightTexture0, lightCoord, ddx(linearLightCoord), ddy(linearLightCoord)).w * shadow;
#endif

#endif