#if !defined(DEBUG_UTILS_INCLUDED)
#define DEBUG_UTILS_INCLUDED

float4 Padding(const float3 value)
{
    return float4(value, 1);
}

float4 Padding(const float2 value)
{
    return float4(value, 1, 1);
}

float4 DebugNormal(const float3 normal)
{
    return Padding(normal * .5 + .5);
}

#endif