using UnityEngine;

namespace Nessie.Shader.Texel.Editor
{
    public class MaterialUtils
    {
        public enum BlendMode
        {
            Opaque,
            Cutout,
            Fade, // Old school alpha-blending mode, fresnel does not affect amount of transparency
            Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
        }

        private struct MaterialSettings
        {
            public string RenderType;
            public int Queue;
            
            public float SrcBlend;
            public float DstBlend;
            public float ZWrite;

            public bool AlphaTest;
            public bool AlphaBlend;
            public bool AlphaPremultiply;
        }
        
        public static void SetMaterialMode(Material material, BlendMode mode, bool overrideRenderQueue = true)
        {
            MaterialSettings ms = GetMaterialModeSettings(mode);

            material.SetOverrideTag("RenderType", ms.RenderType);
            if (overrideRenderQueue) material.renderQueue = ms.Queue;
            material.SetFloat("_SrcBlend", ms.SrcBlend);
            material.SetFloat("_DstBlend", ms.DstBlend);
            material.SetFloat("_ZWrite", ms.ZWrite);
            SetKeyword(material, "_ALPHATEST_ON", ms.AlphaTest);
            SetKeyword(material, "_ALPHABLEND_ON", ms.AlphaBlend);
            SetKeyword(material, "_ALPHAPREMULTIPLY_ON", ms.AlphaPremultiply);
        }

        private static MaterialSettings GetMaterialModeSettings(BlendMode mode)
        {
            MaterialSettings ms = new MaterialSettings();
            switch (mode)
            {
                case BlendMode.Cutout:
                    ms.RenderType = "TransparentCutout";
                    ms.Queue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    
                    ms.SrcBlend = (float)UnityEngine.Rendering.BlendMode.One;
                    ms.DstBlend = (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                    ms.ZWrite = 1f;

                    ms.AlphaTest = true;
                    break;
                case BlendMode.Fade:
                    ms.RenderType = "Transparent";
                    ms.Queue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    
                    ms.SrcBlend = (float)UnityEngine.Rendering.BlendMode.One;
                    ms.DstBlend = (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                    ms.ZWrite = 0f;

                    ms.AlphaBlend = true;
                    break;
                case BlendMode.Transparent:
                    ms.RenderType = "Transparent";
                    ms.Queue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    
                    ms.SrcBlend = (float)UnityEngine.Rendering.BlendMode.One;
                    ms.DstBlend = (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                    ms.ZWrite = 0f;

                    ms.AlphaPremultiply = true;
                    break;
                case BlendMode.Opaque:
                default:
                    ms.RenderType = "";
                    ms.Queue = (int)UnityEngine.Rendering.RenderQueue.Geometry;

                    ms.SrcBlend = (float)UnityEngine.Rendering.BlendMode.One;
                    ms.DstBlend = (float)UnityEngine.Rendering.BlendMode.Zero;
                    ms.ZWrite = 1f;
                    
                    break;
            }

            return ms;
        }
        
        private static void SetKeyword(Material m, string keyword, bool state)
        {
            if (state)
                m.EnableKeyword(keyword);
            else
                m.DisableKeyword(keyword);
        }
    }
}