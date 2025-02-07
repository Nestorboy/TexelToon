using UnityEditor;
using UnityEngine;

namespace Nessie.Shader.Texel.Editor
{
    public class TexelToonGUI : ShaderGUI
    {
        private MaterialProperty _propRenderingMode = null;

        private MaterialProperty _propMainTex = null;
        private MaterialProperty _propColor = null;
        private MaterialProperty _propCutoff = null;
        private MaterialProperty _propGlossMap = null;
        private MaterialProperty _propGlossiness = null;
        private MaterialProperty _propMetalMap = null;
        private MaterialProperty _propMetallic = null;
        private MaterialProperty _propNormalMap = null;
        private MaterialProperty _propNormalScale = null;
        private MaterialProperty _propOcclusionMap = null;
        private MaterialProperty _propOcclusion = null;
        private MaterialProperty _propEmissionMap = null;
        private MaterialProperty _propEmission = null;

        private MaterialProperty _propOutlineWidth = null;
        private MaterialProperty _propOutlineColor = null;

        private MaterialProperty _propTexelMode = null;
        private MaterialProperty _propTexelAA = null;
        private MaterialProperty _propTexelDensity = null;
        private MaterialProperty _propTexelMultiplier = null;

        private MaterialProperty _propColorLUT = null;
        private MaterialProperty _propDithering = null;

        private MaterialProperty _propCullMode = null;

        private MaterialEditor _editor;
        private MaterialProperty[] _properties;

        private static bool _initialized;
        private static bool _albedoFoldout;
        private static bool _normalFoldout;
        private static bool _occlusionFoldout;
        
        public void CacheProperties(MaterialProperty[] props)
        {
            _propRenderingMode   = FindProperty(PropNames.RenderingMode, props);

            _propMainTex         = FindProperty(PropNames.MainTex, props);
            _propColor           = FindProperty(PropNames.Color, props);
            _propCutoff          = FindProperty(PropNames.Cutoff, props);
            _propGlossMap        = FindProperty(PropNames.GlossMap, props);
            _propGlossiness      = FindProperty(PropNames.Glossiness, props);
            _propMetalMap        = FindProperty(PropNames.MetalMap, props);
            _propMetallic        = FindProperty(PropNames.Metallic, props);
            _propNormalMap       = FindProperty(PropNames.BumpMap, props);
            _propNormalScale     = FindProperty(PropNames.BumpScale, props);
            _propOcclusionMap    = FindProperty(PropNames.OcclusionMap, props);
            _propOcclusion       = FindProperty(PropNames.Occlusion, props);
            _propEmissionMap     = FindProperty(PropNames.EmissionMap, props);
            _propEmission        = FindProperty(PropNames.Emission, props);

            _propOutlineWidth    = FindProperty(PropNames.OutlineWidth, props, false);
            _propOutlineColor    = FindProperty(PropNames.OutlineColor, props, false);

            _propTexelMode       = FindProperty(PropNames.TexelMode, props);
            _propTexelAA         = FindProperty(PropNames.TexelAA, props);
            _propTexelDensity    = FindProperty(PropNames.TexelDensity, props);
            _propTexelMultiplier = FindProperty(PropNames.TexelMultiplier, props);

            _propColorLUT        = FindProperty(PropNames.ColorLUT, props);
            _propDithering       = FindProperty(PropNames.Dithering, props);

            _propCullMode        = FindProperty(PropNames.CullMode, props);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _editor = materialEditor;
            _properties = properties;
            CacheProperties(_properties);
            if (!_initialized)
            {
                _initialized = true;

                // Temporary solution.
                Styles.BlendNames[3] += " (Not Implemented)";
            }

            using (new EditorGUI.IndentLevelScope())
            {
                using (EditorGUI.ChangeCheckScope check = new EditorGUI.ChangeCheckScope())
                {
                    DrawRenderMode();

                    EditorGUILayout.Space();
                    GUILayout.Label("Main Maps", EditorStyles.boldLabel);
                    DrawAlbedo();
                    DrawSmoothness();
                    DrawMetallic();
                    DrawNormal();
                    DrawOcclusion();
                    DrawEmission();

                    DrawOutline();
                    DrawTexel();

                    DrawAdvanced();

                    if (check.changed)
                    {
                        
                    }
                }
            }

            //base.OnGUI(materialEditor, properties);
        }

        private void DrawRenderMode()
        {
            if (_propRenderingMode == null) return;

            bool oldShowMixed = EditorGUI.showMixedValue;
            EditorGUI.showMixedValue = _propRenderingMode.hasMixedValue;

            MaterialUtils.BlendMode mode = (MaterialUtils.BlendMode)_propRenderingMode.floatValue;
            using EditorGUI.ChangeCheckScope check = new EditorGUI.ChangeCheckScope();
            mode = (MaterialUtils.BlendMode)EditorGUILayout.Popup(Styles.RenderingMode, (int)mode, Styles.BlendNames);
            bool validMode = mode is MaterialUtils.BlendMode.Opaque or MaterialUtils.BlendMode.Cutout or MaterialUtils.BlendMode.Fade;
            if (check.changed && validMode)
            {
                _editor.RegisterPropertyChangeUndo("Rendering Mode");
                _propRenderingMode.floatValue = (float)mode;
                foreach (Object target in _editor.targets)
                {
                    MaterialUtils.SetMaterialMode(target as Material, mode);
                }
            }

            EditorGUI.showMixedValue = oldShowMixed;
        }

        private void DrawAdvanced()
        {
            EditorGUILayout.Space();
            GUILayout.Label("Advanced Settings", EditorStyles.boldLabel);

            _editor.ShaderProperty(_propCullMode, Styles.TextCullMode);

            _editor.RenderQueueField();

            _editor.EnableInstancingField();
            _editor.DoubleSidedGIField();
        }
        
        private void DrawAlbedo()
        {
            _editor.TexturePropertySingleLine(Styles.TextAlbedo, _propMainTex, _propColor);

            Rect lastRect = GUILayoutUtility.GetLastRect();
            _albedoFoldout = EditorGUI.Foldout(lastRect, _albedoFoldout, "");
            if (_albedoFoldout)
            {
                _editor.TextureScaleOffsetProperty(_propMainTex);
            }

            if ((MaterialUtils.BlendMode)_propRenderingMode.floatValue == MaterialUtils.BlendMode.Cutout)
            {
                _editor.ShaderProperty(_propCutoff, Styles.TextAlphaCutoff, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
            }
        }

        private void DrawSmoothness()
        {
            _editor.TexturePropertySingleLine(Styles.TextSmoothness, _propGlossMap, _propGlossiness);
        }

        private void DrawMetallic()
        {
            _editor.TexturePropertySingleLine(Styles.TextMetallicMap, _propMetalMap, _propMetallic);
        }

        private void DrawNormal()
        {
            _editor.TexturePropertySingleLine(Styles.TextNormalMap, _propNormalMap, _propNormalScale);

            Rect lastRect = GUILayoutUtility.GetLastRect();
            _normalFoldout = EditorGUI.Foldout(lastRect, _normalFoldout, "");
            if (_normalFoldout)
            {
                _editor.TextureScaleOffsetProperty(_propNormalMap);
            }
        }

        private void DrawOcclusion()
        {
            _editor.TexturePropertySingleLine(Styles.TextOcclusion, _propOcclusionMap, _propOcclusion);

            Rect lastRect = GUILayoutUtility.GetLastRect();
            _occlusionFoldout = EditorGUI.Foldout(lastRect, _occlusionFoldout, "");
            if (_occlusionFoldout)
            {
                _editor.TextureScaleOffsetProperty(_propOcclusionMap);
            }
        }

        private void DrawEmission()
        {
            _editor.TexturePropertySingleLine(Styles.TextEmission, _propEmissionMap, _propEmission);
        }

        private void DrawOutline()
        {
            if (_propOutlineWidth == null || _propOutlineColor == null) return;

            EditorGUILayout.Space();
            GUILayout.Label("Outline Settings", EditorStyles.boldLabel);

            _editor.ShaderProperty(_propOutlineWidth, Styles.TextOutlineWidth);
            _editor.ShaderProperty(_propOutlineColor, Styles.TextOutlineColor);
        }

        private void DrawTexel()
        {
            EditorGUILayout.Space();
            GUILayout.Label("Texel Settings", EditorStyles.boldLabel);

            _editor.ShaderProperty(_propTexelAA, Styles.TextTexelAA);
            _editor.ShaderProperty(_propTexelMode, Styles.TextTexelMode);
            using (new EditorGUI.DisabledGroupScope(_propTexelMode.floatValue != 1f))
            {
                DrawVectorProperty(_propTexelDensity, Styles.TextTexelDensity);
            }
            DrawVectorProperty(_propTexelMultiplier, Styles.TextTexelMultiplier);

            _editor.TexturePropertySingleLine(Styles.TextColorLUT, _propColorLUT);
            _editor.ShaderProperty(_propDithering, Styles.TextDithering);
        }

        private void DrawVectorProperty(MaterialProperty property, GUIContent label)
        {
            #if UNITY_2021_3_OR_NEWER
                _editor.VectorProperty(property, label);
            #else
                _editor.VectorProperty(property, label.text);
            #endif
        }
    }
}
