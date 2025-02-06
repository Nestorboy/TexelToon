#if !defined(TEXEL_LIGHTING_INCLUDED)
#define TEXEL_LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "TexelAutoLight.cginc"
#include "TexelLightingInput.cginc"
#include "TexelLightingUtils.cginc"
#include "CGIncludes/VRChatShaderGlobals.cginc"

#define MATRIX_RIGHT(mat) (mat._m00_m10_m20)
#define MATRIX_UP(mat) (mat._m01_m11_m21)
#define MATRIX_FORWARD(mat) (mat._m02_m12_m22)
#define MATRIX_TRANSLATION(mat) (mat._m03_m13_m23)

struct Attributes
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float4 tangent : TEXCOORD2;
    float3 worldPos : TEXCOORD3;
    centroid float2 uvCentroid : TEXCOORD9;

    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD4;
    #endif

    //#if defined(LIGHTMAP_ON)
        float4 ambientOrLightmapUV : TEXCOORD5;
    //#endif

    UNITY_LIGHTING_COORDS(6, 7)
    UNITY_FOG_COORDS(8)

    UNITY_VERTEX_OUTPUT_STEREO
};

struct LightAndAttenuation
{
    UnityLight light;
    float attenuation;
};

// TODO: Create better texel struct with linear source data.
LightAndAttenuation CreateLight(Varyings input, float3 linearWorldPos)
{
    UnityLight light;

    #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
        light.dir = normalize(_WorldSpaceLightPos0.xyz - input.worldPos);
    #else
        light.dir = _WorldSpaceLightPos0.xyz;
    #endif

    #if defined(SHADOWS_SCREEN)
        float4 clipPos = mul(UNITY_MATRIX_VP, float4(input.worldPos, 1));
        input._ShadowCoord = ComputeScreenPos(clipPos);
    #endif
    // TODO: Figure out way to combat center sample being occluded.
    // TODO: Fix spotlight mip artifacts.
    TEXEL_LIGHT_ATTENUATION(attenuation, input, input.worldPos, linearWorldPos);
    #if defined(FORWARD_BASE_PASS)
        float4 ddxy = float4(ddx(input.uv), ddy(input.uv));
        attenuation *= GetOcclusion(input.uvCentroid, ddxy);
    #endif

    light.color = _LightColor0.rgb * attenuation;

    light.ndotl = DotClamped(input.normal, light.dir);

    LightAndAttenuation la;
    la.light = light;
    la.attenuation = attenuation;
    return la;
}

half3 ComputeSpecular(Varyings input, float3 viewDir)
{
    float3 reflDir = reflect(-viewDir, input.normal);
    float4 ddxy = float4(ddx(input.uv), ddy(input.uv));
    float glossiness = GetSmoothness(TexelAA(input.uv, _SpecGlossMap_TexelSize), ddxy);
    
    Unity_GlossyEnvironmentData envData;
    envData.roughness =  1 - glossiness;
    envData.reflUVW = BoxProjection(reflDir, input.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    half3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);

    half3 specular = probe0;
    #if UNITY_SPECCUBE_BLENDING
        float interpolator = unity_SpecCube0_BoxMin.w;
        UNITY_BRANCH
        if (interpolator < 0.99999)
        {
            envData.reflUVW = BoxProjection(reflDir, input.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
            half3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
            specular = lerp(probe1, probe0, interpolator);
        }
    #endif
    
    return specular;
}

UnityIndirect CreateIndirect(Varyings input, float3 viewDir)
{
    UnityIndirect indirect;
    indirect.diffuse = 0;
    indirect.specular = 0;

    #if defined(VERTEXLIGHT_ON)
        indirect.diffuse = input.vertexLightColor;
    #endif

    float4 lightmapUV;
    float3 ambient;
    #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
        ambient = 0;
        lightmapUV = input.ambientOrLightmapUV;
    #else
        ambient = input.ambientOrLightmapUV.rgb;
        lightmapUV = 0;
    #endif

    #if UNITY_SHOULD_SAMPLE_SH
        indirect.diffuse = ShadeSHPerPixel(input.normal, ambient, input.worldPos);
    #endif

    #if defined(UNITY_PASS_FORWARDBASE)
        #if defined(LIGHTMAP_ON)
            indirect.diffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, input.ambientOrLightmapUV));

            #if defined(DIRLIGHTMAP_COMBINED)
                float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, input.ambientOrLightmapUV);
            #else
                // Is this correct?
                float3 shColor = ShadeSH9(float4(input.normal, 1));
                indirect.diffuse += max(0, shColor);
            #endif
        #endif
        
        indirect.specular = ComputeSpecular(input, viewDir);

        float4 ddxy = float4(ddx(input.uv), ddy(input.uv));
        float occlusion = GetOcclusion(input.uvCentroid, ddxy);
        indirect.diffuse *= occlusion;
        indirect.specular *= occlusion;
    #endif

    return indirect;
}

inline half4 VertexGIForward(Attributes v, float3 posWorld, half3 normalWorld)
{
    half4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #ifdef LIGHTMAP_ON
        ambientOrLightmapUV.xy = v.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}

Varyings TexelVert(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_OUTPUT(Varyings, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.pos = UnityObjectToClipPos(input.vertex);
    output.normal = UnityObjectToWorldNormal(input.normal);
    output.tangent = float4(UnityObjectToWorldDir(input.tangent.xyz), input.tangent.w);
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    output.uvCentroid = output.uv;
    // The object pivot position is ignored here and it will be added after texel snapping to improve the precision of it.
    output.worldPos = mul(unity_ObjectToWorld, float4(input.vertex.xyz, 0));

    output.ambientOrLightmapUV = VertexGIForward(input, output.worldPos, output.normal);
    //#if defined(LIGHTMAP_ON)
    //    output.ambientOrLightmapUV.xy = input.uv2 * unity_LightmapST.xy + unity_LightmapST.zw;
    //#endif

    // Why does unity assume my input is called v? ):
    #define v input
    UNITY_TRANSFER_LIGHTING(output, input.uv2);
    #undef v
    UNITY_TRANSFER_FOG(output, output.pos);

    return output;
}

void InitializeFragmentNormal(inout Varyings input)
{
    float4 ddxy = float4(ddx(input.uv), ddy(input.uv));
    float3 tangentNormal = GetTangentSpaceNormal(input.uv, ddxy);
    half sign = input.tangent.w * unity_WorldTransformParams.w;
    float3 binormal = cross(input.normal, input.tangent.xyz) * sign;
    input.normal = normalize(
        tangentNormal.x * input.tangent +
        tangentNormal.y * binormal +
        tangentNormal.z * input.normal);
}

void InitializeFragmentInterpolators(inout Varyings input)
{
    float2 uv = input.uv;
    float4 texelSize;
    #if defined(_TEXELMODE_AUTO)
        texelSize = _MainTex_TexelSize;
    #else
        texelSize = float4(1 / _TexelDensity.xy, _TexelDensity.xy);
    #endif
    texelSize *= float4(1 / _TexelDensityMultiplier.xy, _TexelDensityMultiplier.xy);
    
    // Pixelate interpolated data. No more interpolated vertex data, goodbye.
    // TODO: Figure out why normalizing data makes it more flat.
    input.normal = TexelSnap(input.normal, uv, texelSize);
    input.tangent = TexelSnap(input.tangent, uv, texelSize);
    input.worldPos = TexelSnap(input.worldPos, uv, texelSize);
    input.worldPos += MATRIX_TRANSLATION(unity_ObjectToWorld);

    #if defined(LIGHTMAP_ON)
        input.ambientOrLightmapUV = TexelSnap(input.ambientOrLightmapUV, uv, texelSize);
    #endif

    input.normal = normalize(input.normal);
    input.tangent.xyz = normalize(input.tangent.xyz);
}

half4 TexelFrag(Varyings input) : SV_Target
{
    float3 worldPos = input.worldPos;
    float2 uv = input.uv;
    float2 uvC = input.uvCentroid;
    InitializeFragmentInterpolators(input);
    InitializeFragmentNormal(input);

    // Compute derivatives of regular uv for proper mips when using TexelAA.
    float4 ddxy = float4(ddx(uv), ddy(uv));

    half4 albedo = GetAlbedo(uvC, ddxy);
    #if defined(_ALPHATEST_ON)
        clip(albedo.a - _Cutoff);
    #endif

    // TODO: Figure out proper metallic + glossiness workflow.
    half metallic = GetMetallic(uvC, ddxy);
    half3 specularTint;
    half oneMinusReflectivity;
    albedo.rgb = DiffuseAndSpecularFromMetallic(albedo, metallic, specularTint, oneMinusReflectivity);

    float glossiness = GetSmoothness(uv, ddxy);

    float3 viewDir = normalize(_CenteredCameraPos - input.worldPos);

    LightAndAttenuation lightAttenuation = CreateLight(input, worldPos);
    UnityIndirect indirect = CreateIndirect(input, viewDir);

    half4 finalColor = UNITY_BRDF_PBS( // TODO: Figure out why macro can't be resolved.
    //float4 finalColor = BRDF3_Unity_PBS(
        albedo, specularTint, oneMinusReflectivity, glossiness,
        input.normal, viewDir,
        lightAttenuation.light, indirect);

    #if defined(UNITY_PASS_FORWARDBASE)
        finalColor.rgb += GetEmission(uvC, ddxy);
    #endif

    int width, height;
    _ColorLUT.GetDimensions(width, height);
    bool hasPaletteLUT = width != 4 || height != 4;
    bool applyLUT = hasPaletteLUT;
    #if defined(UNITY_PASS_FORWARDADD)
        applyLUT = applyLUT && lightAttenuation.attenuation != 0;
    #endif
    if (applyLUT)
    {
        #if defined(_DITHER_ON)
        float4 texelSize;
        #if defined(_TEXELMODE_AUTO)
            texelSize = _MainTex_TexelSize;
        #else
            texelSize = float4(1 / _TexelDensity.xy, _TexelDensity.xy);
        #endif
        texelSize *= float4(1 / _TexelDensityMultiplier.xy, _TexelDensityMultiplier.xy);

        // TODO: Improve ID computation.
        uint2 id = floor(uv * texelSize.zw * sign(uv) - min(0, sign(uv))) % 4;
        float DITHER_THRESHOLDS[16] =
        {
            1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
            13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
            4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
            16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
        };
        // TODO: Consider exposing strength.
        finalColor += DITHER_THRESHOLDS[id.x * 4 + id.y % 4] / 512.;
        #endif

        finalColor.rgb = ApplyPointLut2D(_ColorLUT, finalColor.rgb, float3(_ColorLUT_TexelSize.xy, _ColorLUT_TexelSize.w - 1));
    }

    UNITY_APPLY_FOG(input.fogCoord, finalColor.rgb);

    return finalColor;
}

#endif