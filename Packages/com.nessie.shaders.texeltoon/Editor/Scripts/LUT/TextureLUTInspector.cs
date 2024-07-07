using System.Collections.Generic;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEditor.AssetImporters;
using UnityEditorInternal;
using UnityEngine;

namespace Nessie.Shader.Texel.LUT
{
    [CanEditMultipleObjects]
    [CustomEditor(typeof(TextureLUTImporter), true)]
    public class TextureLUTInspector : ScriptedImporterEditor
    {
        private SerializedProperty _textureShapeProp;
        private SerializedProperty _isReadableProp;
        private SerializedProperty _filterModeProp;
        private SerializedProperty _stepsPerColorProp;
        private SerializedProperty _paletteProp;

        private ReorderableList _paletteRList;

        public override void OnEnable()
        {
            base.OnEnable();

            InitProps();
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.PropertyField(_textureShapeProp);
            EditorGUILayout.PropertyField(_isReadableProp);
            EditorGUILayout.PropertyField(_filterModeProp);

            EditorGUILayout.Separator();

            DrawPaletteButtons();
            EditorGUILayout.PropertyField(_stepsPerColorProp);
            EditorGUILayout.PropertyField(_paletteProp);

            serializedObject.ApplyModifiedProperties();
            ApplyRevertGUI();
        }

        private void InitProps()
        {
            _textureShapeProp = serializedObject.FindProperty("TextureShape");
            _isReadableProp = serializedObject.FindProperty("IsReadable");
            _filterModeProp = serializedObject.FindProperty("FilterMode");
            _stepsPerColorProp = serializedObject.FindProperty("StepsPerColor");
            _paletteProp = serializedObject.FindProperty("Palette");

            _paletteRList = new ReorderableList(serializedObject, _paletteProp);
        }

        private void DrawPaletteButtons()
        {
            EditorGUILayout.BeginHorizontal();

            if (GUILayout.Button("Import palette from clipboard"))
            {
                Color[] palette = GetHTMLPalette();
                _paletteProp.arraySize = palette.Length;
                for (int i = 0; i < palette.Length; i++)
                {
                    SerializedProperty prop = _paletteProp.GetArrayElementAtIndex(i);
                    prop.colorValue = palette[i];
                }
            }

            if (GUILayout.Button("Clear palette"))
            {
                _paletteProp.ClearArray();
            }

            EditorGUILayout.EndHorizontal();
        }

        private Color[] GetHTMLPalette()
        {
            string clipBoard = GUIUtility.systemCopyBuffer;
        
            MatchCollection matches = Regex.Matches(clipBoard, @"#(?:[0-9a-fA-F]{2}){3,4}");
            HashSet<Color> colorSet = new HashSet<Color>();
            for (int i = 0; i < matches.Count; i++)
            {
                string hex = matches[i].Value;
                if (!ColorUtility.TryParseHtmlString(hex, out Color color))
                {
                    continue;
                }

                colorSet.Add(color);
            }

            Color[] colorArray = new Color[colorSet.Count];
            colorSet.CopyTo(colorArray);

            return colorArray;
        }
    }
}