/*
contributors: [Patricio Gonzalez Vivo, Shadi El Hajj]
description: Calculate point light
use: lightPointEvaluate(<vec3> _diffuseColor, <vec3> _specularColor, <vec3> _N, <vec3> _V, <float> _NoV, <float> _f0, out <vec3> _diffuse, out <vec3> _specular)
options:
    - DIFFUSE_FNC: diffuseOrenNayar, diffuseBurley, diffuseLambert (default)
    - SURFACE_POSITION: in glslViewer is v_position
    - LIGHT_POSITION: in glslViewer is u_light
    - LIGHT_COLOR: in glslViewer is u_lightColor
    - LIGHT_INTENSITY: in glslViewer is  u_lightIntensity
    - LIGHT_FALLOFF: in glslViewer is u_lightFalloff
license:
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Prosperity License - https://prosperitylicense.com/versions/3.0.0
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Patron License - https://lygia.xyz/license
*/

#include "../specular.glsl"
#include "../diffuse.glsl"
#include "falloff.glsl"

#ifndef FNC_LIGHT_POINT
#define FNC_LIGHT_POINT

void lightPointEvaluate(LightPoint L, Material mat, inout ShadingData shadingData) {

    float Ldist  = length(L.position);
    vec3 Ldirection = L.position/Ldist;
    shadingData.L = Ldirection;
    shadingData.H = normalize(Ldirection + shadingData.V);
    shadingData.NoL = dot(shadingData.N, Ldirection);
    shadingData.NoH = dot(shadingData.N, shadingData.H);

    #ifdef FNC_RAYMARCH_SOFTSHADOW    
    float shadow = raymarchSoftShadow(mat.position, Ldirection);
    #else
    float shadow = 1.0;
    #endif

    float dif  = diffuse(shadingData);
    float spec = specular(shadingData);

    vec3 lightContribution = L.color * L.intensity * shadow * shadingData.NoL;
    if (L.falloff > 0.0)
        lightContribution *= falloff(Ldist, L.falloff);

    shadingData.diffuse  += max(vec3(0.0, 0.0, 0.0), shadingData.diffuseColor * lightContribution * dif);
    shadingData.specular += max(vec3(0.0, 0.0, 0.0), shadingData.specularColor * lightContribution * spec);

    // TODO:
    // - make sure that the shadow use a perspective projection
    #ifdef SHADING_MODEL_SUBSURFACE
    float scatterVoH = saturate(dot(shadingData.V, -Ldirection));
    float forwardScatter = exp2(scatterVoH * mat.subsurfacePower - mat.subsurfacePower);
    float backScatter = saturate(shadingData.NoL * mat.subsurfaceThickness + (1.0 - mat.subsurfaceThickness)) * 0.5;
    float subsurface = mix(backScatter, 1.0, forwardScatter) * (1.0 - mat.subsurfaceThickness);
    shadingData.diffuse += mat.subsurfaceColor * (subsurface * diffuseLambertConstant());
    #endif
}

#endif
