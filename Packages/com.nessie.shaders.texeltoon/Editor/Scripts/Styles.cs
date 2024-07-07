using System;
using UnityEngine;
using UnityEditor;

namespace Nessie.Shader.Texel.Editor
{
    public static class Styles
    {
        public static readonly GUIContent TextAlbedo = EditorGUIUtility.TrTextContent("Albedo", "Albedo (RGB) and Transparency (A)");
        public static readonly GUIContent TextAlphaCutoff = EditorGUIUtility.TrTextContent("Alpha Cutoff", "Threshold for alpha cutoff");
        //public static readonly GUIContent TextSpecularMap = EditorGUIUtility.TrTextContent("Specular", "Specular (RGB) and Smoothness (A)");
        public static readonly GUIContent TextMetallicMap = EditorGUIUtility.TrTextContent("Metallic", "Metallic (R) and Smoothness (A)");
        public static readonly GUIContent TextSmoothness = EditorGUIUtility.TrTextContent("Smoothness", "Smoothness value");
        //public static readonly GUIContent TextSmoothnessScale = EditorGUIUtility.TrTextContent("Smoothness", "Smoothness scale factor");
        //public static readonly GUIContent TextSmoothnessMapChannel = EditorGUIUtility.TrTextContent("Source", "Smoothness texture and channel");
        //public static readonly GUIContent TextHighlights = EditorGUIUtility.TrTextContent("Specular Highlights", "Specular Highlights");
        //public static readonly GUIContent TextReflections = EditorGUIUtility.TrTextContent("Reflections", "Glossy Reflections");
        public static readonly GUIContent TextNormalMap = EditorGUIUtility.TrTextContent("Normal", "Normal Map");
        //public static readonly GUIContent TextHeightMap = EditorGUIUtility.TrTextContent("Height Map", "Height Map (G)");
        public static readonly GUIContent TextOcclusion = EditorGUIUtility.TrTextContent("Occlusion", "Occlusion (G)");
        public static readonly GUIContent TextEmission = EditorGUIUtility.TrTextContent("Emission", "Emission (RGB)");
        //public static readonly GUIContent TextDetailMask = EditorGUIUtility.TrTextContent("Detail Mask", "Mask for Secondary Maps (A)");
        //public static readonly GUIContent TextDetailAlbedo = EditorGUIUtility.TrTextContent("Detail Albedo x2", "Albedo (RGB) multiplied by 2");
        //public static readonly GUIContent TextDetailNormalMap = EditorGUIUtility.TrTextContent("Normal Map", "Normal Map");
        
        public static readonly GUIContent TextOutlineWidth = EditorGUIUtility.TrTextContent("Outline Width", "Width of the outline");
        public static readonly GUIContent TextOutlineColor = EditorGUIUtility.TrTextContent("Outline Color", "Unlit (RGB)");
        
        public static readonly GUIContent TextTexelAA = EditorGUIUtility.TrTextContent("Texel AA", "Apply additional anti-aliasing step before using textures");
        public static readonly GUIContent TextTexelMode = EditorGUIUtility.TrTextContent("Texel Mode", "Determines if the texel shading density should be based on main texture or be manual");
        public static readonly GUIContent TextTexelDensity = EditorGUIUtility.TrTextContent("Texel Density", "Manually defines texel shading resolution");
        public static readonly GUIContent TextTexelMultiplier = EditorGUIUtility.TrTextContent("Texel Multiplier", "Multiplier for texel shading density");
        
        public static readonly GUIContent TextColorLUT = EditorGUIUtility.TrTextContent("Color LUT", "Look up table used to snap colors to their nearest correspondent");
        public static readonly GUIContent TextDithering = EditorGUIUtility.TrTextContent("Dithering", "Applies dithering for the LUT");
        
        public static readonly GUIContent TextCullMode = EditorGUIUtility.TrTextContent("Cull Mode", "Which face of the polygon should be culled from rendering");
        
        public static readonly string RenderingMode = "Rendering Mode";
        public static readonly string[] BlendNames = Enum.GetNames(typeof(MaterialUtils.BlendMode));
    }
}
