#if !defined(TEXEL_LIGHTING_UNIFORMS_INCLUDED)
#define TEXEL_LIGHTING_UNIFORMS_INCLUDED

#include "UnityGlobalIllumination.cginc"
#include "TexelLightingUtils.cginc"

UNITY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST;
float4 _MainTex_TexelSize;

fixed4 _Color;

UNITY_DECLARE_TEX2D(_SpecGlossMap);
float4 _SpecGlossMap_TexelSize;
float _Glossiness;

UNITY_DECLARE_TEX2D(_MetallicGlossMap);
float4 _MetallicGlossMap_TexelSize;
float _Metallic;

UNITY_DECLARE_TEX2D(_BumpMap);
float _BumpScale;

UNITY_DECLARE_TEX2D(_OcclusionMap);
float4 _OcclusionMap_TexelSize;
float _OcclusionStrength;

UNITY_DECLARE_TEX2D(_EmissionMap);
float4 _EmissionMap_TexelSize;
float4 _EmissionColor;

float _Cutoff;

float2 _TexelDensity;
float2 _TexelDensityMultiplier;

UNITY_DECLARE_TEX2D(_ColorLUT);
float4 _ColorLUT_TexelSize;

half4 GetAlbedo(float2 uv, float4 ddxy)
{
    half4 albedoMap = UNITY_SAMPLE_TEX2D_GRAD(_MainTex, TexelAA(uv, _MainTex_TexelSize), ddxy.xy, ddxy.zw);
    return albedoMap * _Color;
}

// Can't use TexelAA since it determines how sharp reflections are and it would make them spread out more.
half GetSmoothness(float2 uv, float4 ddxy)
{
    half glossMap = UNITY_SAMPLE_TEX2D_GRAD(_SpecGlossMap, TexelStep(uv, _SpecGlossMap_TexelSize), ddxy.xy, ddxy.zw);
    return glossMap * _Glossiness;
}

half GetMetallic(float2 uv, float4 ddxy)
{
    half metallicMap = UNITY_SAMPLE_TEX2D_GRAD(_MetallicGlossMap, TexelAA(uv, _MetallicGlossMap_TexelSize), ddxy.xy, ddxy.zw);
    return metallicMap * _Metallic;
}

// Can't make use of TexelAA since data would mess with lighting calculations and cause artifacts.
half3 GetTangentSpaceNormal(float2 uv, float4 ddxy)
{
    half4 packedNormal = UNITY_SAMPLE_TEX2D_GRAD(_BumpMap, TexelStep(uv, _MainTex_TexelSize), ddxy.xy, ddxy.zw);
    return UnpackScaleNormal(packedNormal, _BumpScale);
}

// TODO: Add TexelAA
half GetOcclusion(float2 uv, float4 ddxy)
{
    half occlusionMap = UNITY_SAMPLE_TEX2D_GRAD(_OcclusionMap, TexelAA(uv, _OcclusionMap_TexelSize), ddxy.xy, ddxy.zw);
    return lerp(1, occlusionMap, _OcclusionStrength);
}

half3 GetEmission(float2 uv, float4 ddxy)
{
    half4 emissionMap = UNITY_SAMPLE_TEX2D_GRAD(_EmissionMap, TexelAA(uv, _EmissionMap_TexelSize), ddxy.xy, ddxy.zw);
    return emissionMap.rgb * emissionMap.a * _EmissionColor;
}

#endif