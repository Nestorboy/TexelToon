using System;
using UnityEditor;
using UnityEditor.AssetImporters;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace Nessie.Shader.Texel.LUT
{
    public enum LUTImporterShape
    {
        Texture2D,
        Texture3D
    }

    [CanEditMultipleObjects]
    [ScriptedImporter(VERSION_NUMBER, FILE_EXTENSION)]
    public class TextureLUTImporter : ScriptedImporter
    {
        public const string FILE_EXTENSION = "texturelut";

        public const int VERSION_NUMBER = 1;

        [Tooltip("The shape of the texture.")]
        [SerializeField] private LUTImporterShape TextureShape = LUTImporterShape.Texture2D;

        [SerializeField] private bool IsReadable;

        [SerializeField] private FilterMode FilterMode = FilterMode.Bilinear;

        [Tooltip("The amount of steps each channel should have.")]
        [SerializeField] [Min(1)] private int StepsPerColor = 16;

        [Tooltip("List of colors used for LUT.")]
        [SerializeField] private Color[] Palette = new Color[0];

        public override void OnImportAsset(AssetImportContext ctx)
        {
            switch (TextureShape)
            {
                case LUTImporterShape.Texture2D: Import2DLUT(ctx); break;
                case LUTImporterShape.Texture3D: Import3DLUT(ctx); break;
                default: throw new ArgumentOutOfRangeException();
            }
        }

        private void Import2DLUT(AssetImportContext ctx)
        {
            bool isValid = true;
            Texture2D lutTex;
            try
            {
                int width = StepsPerColor * StepsPerColor, height = StepsPerColor;
                lutTex = new Texture2D(width, height, TextureFormat.RGB24, false, false);
            }
            catch (Exception e)
            {
                Debug.LogException(e);
                ctx.LogImportError($"Import failed '{ctx.assetPath}'.", ctx.mainObject);

                lutTex = new Texture2D(16, 16, TextureFormat.RGBA32, false);
                isValid = false;
            }

            lutTex.filterMode = FilterMode;

            if (isValid)
            {
                lutTex.SetPixels(GenerateLUT(Palette, StepsPerColor));
            }
            else
            {
                Color[] colors = new Color[16 * 16];
                for (int i = 0; i < colors.Length; i++) colors[i] = Color.magenta;

                lutTex.SetPixels(colors);
            }

            lutTex.Apply(false, !IsReadable);

            ctx.AddObjectToAsset("Texture2D", lutTex);
            ctx.SetMainObject(lutTex);
        }

        private void Import3DLUT(AssetImportContext ctx)
        {
            bool isValid = true;
            Texture3D lutTex;
            try
            {
                int width = StepsPerColor, height = StepsPerColor, depth = StepsPerColor;
                lutTex = new Texture3D(width, height, depth, GraphicsFormat.R8G8B8A8_SRGB, TextureCreationFlags.None);
            }
            catch (Exception e)
            {
                Debug.LogException(e);
                ctx.LogImportError($"Import failed '{ctx.assetPath}'.", ctx.mainObject);

                lutTex = new Texture3D(16, 16, 16, TextureFormat.RGBA32, false);
                isValid = false;
            }

            lutTex.filterMode = FilterMode;

            if (isValid)
            {
                Color[] colors = GenerateLUT(Palette, StepsPerColor);
                lutTex.SetPixels(colors);
            }
            else
            {
                Color[] colors = new Color[16 * 16 * 16];
                for (int i = 0; i < colors.Length; i++) colors[i] = Color.magenta;

                lutTex.SetPixels(colors);
            }

            lutTex.Apply(false, !IsReadable);

            ctx.AddObjectToAsset("Texture3D", lutTex);
            ctx.SetMainObject(lutTex);
        }

        [MenuItem("Assets/Create/Texture LUT", false, priority = 310)]
        private static void CreateTextureLUTMenuItem()
        {
            // https://forum.unity.com/threads/how-to-implement-create-new-asset.759662/#post-7549801
            ProjectWindowUtil.CreateAssetWithContent($"New Texture LUT.{FILE_EXTENSION}", string.Empty);
        }

        private Color[] GenerateLUT(Color[] palette, int steps)
        {
            Color[] pixels = new Color[steps * steps * steps];

            Color[] labPalette = new Color[palette.Length];
            for (int i = 0; i < labPalette.Length; i++)
            {
                labPalette[i] = OklabUtility.LinearSRGBToOklab(palette[i]);
            }

            for (int z = 0; z < steps; z++)
            {
                for (int y = 0; y < steps; y++)
                {
                    for (int x = 0; x < steps; x++)
                    {
                        int i = TextureShape switch
                        {
                            LUTImporterShape.Texture2D => y * steps * steps + z * steps + x,
                            LUTImporterShape.Texture3D => z * steps * steps + y * steps + x,
                            _ => throw new ArgumentOutOfRangeException()
                        };

                        pixels[i] = ComputeColor(x, y, z, labPalette, steps);
                    }
                }
            }

            return pixels;
        }

        private static Color ComputeColor(int x, int y, int z, Color[] palette, int stepCount)
        {
            Color col = new Color(x, y, z) / (stepCount - 1f); // Normalized color.

            if (palette is not { Length: > 0 })
            {
                return col;
            }

            Color lab = OklabUtility.LinearSRGBToOklab(col);
            float minDist = Mathf.Infinity;
            Color bestLab = lab;
            foreach (Color palCol in palette)
            {
                float newDist = ColorSqrDistance(palCol, lab);
                if (newDist < minDist)
                {
                    minDist = newDist;
                    bestLab = palCol;
                }
            }

            return OklabUtility.OklabToLinearSRGB(bestLab);
        }

        private static float ColorSqrDistance(Color a, Color b)
        {
            return new Vector3(a.r - b.r, a.g - b.g, a.b - b.b).sqrMagnitude;
        }
    }
}