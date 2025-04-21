#if !defined(TEXEL_LIGHTING_UTILS_INCLUDED)
#define TEXEL_LIGHTING_UTILS_INCLUDED

// Computes axis-aligned screen space offset to texel center.
// https://forum.unity.com/threads/the-quest-for-efficient-per-texel-lighting.529948/#post-7536023
float2 ComputeTexelOffset(float2 uv, float4 texelSize)
{
    // 1. Calculate how much the texture UV coords need to shift to be at the center of the nearest texel.
    float2 uvCenter = (floor(uv * texelSize.zw) + 0.5) * texelSize.xy;
    float2 dUV = uvCenter - uv;

    // 2. Calculate how much the texture coords vary over fragment space.
    //    This essentially defines a 2x2 matrix that gets texture space (UV) deltas from fragment space (ST) deltas.
    float2 dUVdS = ddx(uv);
    float2 dUVdT = ddy(uv);

    // 3. Invert the texture delta from fragment delta matrix. Where the magic happens.
    float2x2 dSTdUV = float2x2(dUVdT[1], -dUVdT[0], -dUVdS[1], dUVdS[0]) * (1.0 / (dUVdS[0] * dUVdT[1] - dUVdT[0] * dUVdS[1]));

    // 4. Convert the texture delta to fragment delta.
    float2 dST = mul(dSTdUV, dUV);

    return dST;
}

#define TexelSnapTemplate(T)                                                    \
T TexelSnap(T value, float2 uv, float4 texelSize)                               \
{                                                                               \
    /* 1. Get the screen space offset to the texel center. */                   \
    float2 xyOffset = ComputeTexelOffset(uv, texelSize);                        \
                                                                                \
    /* 2. Calculate how much the world coords vary over fragment space. */      \
    T dx = ddx(value);                                                          \
    T dy = ddy(value);                                                          \
                                                                                \
    /* 3. Finally, convert our fragment space delta to a world space delta.
          And be sure to clamp it in case the derivative calc went insane. */   \
    T valueOffset = dx * xyOffset.x + dy * xyOffset.y;                          \
    valueOffset = clamp(valueOffset, -1, 1);                                    \
                                                                                \
    /* 4. Transform the snapped UV back to world space. */                      \
    return value + valueOffset;                                                 \
}

TexelSnapTemplate(float4)
TexelSnapTemplate(float3)
TexelSnapTemplate(float2)
TexelSnapTemplate(float)

float2 PixelateUV(float2 uv, float4 texelSize)
{
    return (floor(uv * texelSize.zw) + .5) * texelSize.xy;
}

// https://www.youtube.com/watch?v=d6tp43wZqps
float2 TexelAA(float2 uv, float4 texelSize) // TODO: Figure out solution for interpolated color messing with LUT.
{
    #if !defined(_TEXEL_AA_ON) // TODO: Move define to separate uv calc function meant for shader to isolate TexelAA responsibility.
        //return uv;
        return PixelateUV(uv, texelSize);
    #endif
    float2 boxSize = clamp(fwidth(uv) * texelSize.zw, 1e-5, 1);
    float2 tx = uv * texelSize.zw - .5 * boxSize;
    //float2 offset = saturate((frac(tx) - (1 - boxSize)) / boxSize); // Perfectly linear.
    float2 offset = smoothstep(1 - boxSize, 1, frac(tx)); // Weighted center.
    return (floor(tx) + .5 + offset) * texelSize.xy;
}

// scaleOffset = (1 / lut_width, 1 / lut_height, lut_height - 1)
float3 ApplyPointLut2D(Texture2D tex, float3 col, float3 scaleOffset)
{
    col = saturate(col);
    if (!IsGammaSpace()) col = LinearToGammaSpace(col);

    uint3 id = round(col * scaleOffset.z);
    uint2 p = (float2(id.x + round(id.z / scaleOffset.y), id.y) + 0.5);
    return tex[p];
}

// Unity has BoxProjectedCubemapDirection(), but it normalizes the provided reflection direction, but we already know it's a unit vector.
float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
    #if UNITY_SPECCUBE_BOX_PROJECTION
        UNITY_BRANCH
        if (cubemapPosition.w > 0)
        {
            boxMin -= position;
            boxMax -= position;
            float x = (direction.x > 0 ? boxMax.x : boxMin.x) / direction.x;
            float y = (direction.y > 0 ? boxMax.y : boxMin.y) / direction.y;
            float z = (direction.z > 0 ? boxMax.z : boxMin.z) / direction.z;
            float scalar = min(min(x, y), z);
            direction = direction * scalar + (position - cubemapPosition);
        }
    #endif
    
    return direction;
}

#ifdef UNITY_SEPARATE_TEXTURE_SAMPLER
    #define UNITY_SAMPLE_TEX2D_GRAD(tex,coord,ddx,ddy) tex.SampleGrad (sampler##tex, coord, ddx, ddy)
#else
    #define UNITY_SAMPLE_TEX2D_GRAD(tex,coord,ddx,ddy) tex2Dgrad (sampler##tex, coord, ddx, ddy)
#endif

#endif