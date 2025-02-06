#ifndef TEXEL_AUTO_LIGHT_INCLUDED
#define TEXEL_AUTO_LIGHT_INCLUDED

#include "AutoLight.cginc"

#ifdef POINT
    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos) \
        unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r * shadow;
#endif

#ifdef SPOT
    inline fixed TexelSpotCookie(unityShadowCoord4 LightCoord)
    {
        return tex2D(_LightTexture0, LightCoord.xy / LightCoord.w + 0.5).w;
    }

    inline fixed TexelSpotAttenuate(unityShadowCoord3 LightCoord)
    {
        return tex2D(_LightTextureB0, dot(LightCoord, LightCoord).xx).r;
    }

    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
        #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1))
    #else
        #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord4 lightCoord = input._LightCoord
    #endif

    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = (lightCoord.z > 0) * TexelSpotCookie(lightCoord) * TexelSpotAttenuate(lightCoord.xyz) * shadow;
#endif

#ifdef DIRECTIONAL
    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos) fixed destName = UNITY_SHADOW_ATTENUATION(input, worldPos);
#endif

#ifdef POINT_COOKIE
    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
        #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz
    #else
        #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord3 lightCoord = input._LightCoord
    #endif

    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r * texCUBE(_LightTexture0, lightCoord).w * shadow;
#endif

#ifdef DIRECTIONAL_COOKIE
    #if !defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS)
        #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord2 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xy
    #else
        #define DECLARE_LIGHT_COORD(input, worldPos) unityShadowCoord2 lightCoord = input._LightCoord
    #endif

    #define TEXEL_LIGHT_ATTENUATION(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, lightCoord).w * shadow;
#endif

#endif