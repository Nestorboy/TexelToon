using UnityEngine;

namespace Nessie.Shader.Texel.LUT
{
    public static class OklabUtility
    {
        public static Color LinearSRGBToOklab(Color c) 
        {
            float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
            float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
            float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;

            l = Cbrt(l);
            m = Cbrt(m);
            s = Cbrt(s);

            return new Color(
                0.2104542553f*l + 0.7936177850f*m - 0.0040720468f*s,
                1.9779984951f*l - 2.4285922050f*m + 0.4505937099f*s,
                0.0259040371f*l + 0.7827717662f*m - 0.8086757660f*s
            );
        }

        public static Color OklabToLinearSRGB(Color c)
        {
            float l = c.r + 0.3963377774f * c.g + 0.2158037573f * c.b;
            float m = c.r - 0.1055613458f * c.g - 0.0638541728f * c.b;
            float s = c.r - 0.0894841775f * c.g - 1.2914855480f * c.b;

            l = Cube(l);
            m = Cube(m);
            s = Cube(s);

            return new Color(
                +4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s,
                -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s,
                -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s
            );
        }

        private static float Cbrt(float f)
        {
            return Mathf.Pow(f, 1f / 3f);
        }

        private static float Cube(float f)
        {
            return f * f * f;
        }
    }
}