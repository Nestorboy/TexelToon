// https://docs.vrchat.com/docs/vrchat-202231#features-1

#ifndef VRCHAT_SHADER_GLOBALS_INCLUDED
#define VRCHAT_SHADER_GLOBALS_INCLUDED

// 0 - Rendering normally
// 1 - Rendering in VR handheld camera
// 2 - Rendering in Desktop handheld camera
// 3 - Rendering for a screenshot
float _VRChatCameraMode;

// 0 - Rendering normally, not in a mirror
// 1 - Rendering in a mirror viewed in VR
// 2 - Rendering in a mirror viewed in desktop mode
float _VRChatMirrorMode;

#define VRCHAT_MIRROR _VRChatMirrorMode != 0

// World space position of mirror camera (eye independent, "centered" in VR)
float3 _VRChatMirrorCameraPos; // In mirror only.

#if defined(USING_STEREO_MATRICES)
    #define _CenteredCameraPos ((unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * 0.5)
#else
    #define _CenteredCameraPos (_VRChatMirrorMode != 0 ? _VRChatMirrorCameraPos : _WorldSpaceCameraPos)
#endif

#endif
