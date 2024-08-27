#include "../specular.glsl"
#include "../diffuse.glsl"

/*
contributors: [Patricio Gonzalez Vivo, Shadi El Hajj]
description: Calculate directional light
use: lightDirectionalEvaluate(<vec3> _diffuseColor, <vec3> _specularColor, <vec3> _N, <vec3> _V, <float> _NoV, <float> _f0, out <vec3> _diffuse, out <vec3> _specular)
options:
    - DIFFUSE_FNC: diffuseOrenNayar, diffuseBurley, diffuseLambert (default)
    - LIGHT_POSITION: in GlslViewer is u_light
    - LIGHT_DIRECTION
    - LIGHT_COLOR: in GlslViewer is u_lightColor
    - LIGHT_INTENSITY: in GlslViewer is u_lightIntensity
    - RAYMARCH_SHADOWS: enable raymarched shadows
license:
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Prosperity License - https://prosperitylicense.com/versions/3.0.0
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Patron License - https://lygia.xyz/license
*/

#ifndef FNC_LIGHT_DIRECTIONAL_EVALUATE
#define FNC_LIGHT_DIRECTIONAL_EVALUATE

void lightDirectionalEvaluate(LightDirectional L, Material mat, inout ShadingData shadingData) {

    shadingData.L = L.direction;
    shadingData.H = normalize(L.direction + shadingData.V);
    shadingData.NoL = dot(shadingData.N, L.direction);
    shadingData.NoH = dot(shadingData.N, shadingData.H);

    #ifdef FNC_RAYMARCH_SOFTSHADOW    
    float shadow = raymarchSoftShadow(mat.position, L.direction);
    #else
    float shadow = 1.0;
    #endif

    float dif  = diffuse(shadingData);
    float spec = specular(shadingData);

    vec3 lightContribution = L.color * L.intensity * shadow * shadingData.NoL;
    shadingData.diffuse  += max(vec3(0.0, 0.0, 0.0), shadingData.diffuseColor * lightContribution * dif);
    shadingData.specular += max(vec3(0.0, 0.0, 0.0), shadingData.specularColor * lightContribution * spec);

    #ifdef SHADING_MODEL_SUBSURFACE
    float scatterVoH = saturate(dot(shadingData.V, -L.direction));
    float forwardScatter = exp2(scatterVoH * mat.subsurfacePower - mat.subsurfacePower);
    float backScatter = saturate(shadingData.NoL * mat.subsurfaceThickness + (1.0 - mat.subsurfaceThickness)) * 0.5;
    float subsurface = mix(backScatter, 1.0, forwardScatter) * (1.0 - mat.subsurfaceThickness);
    shadingData.diffuse += mat.subsurfaceColor * (subsurface * diffuseLambertConstant());
    #endif
}

#endif