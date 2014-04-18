// Uniforms
uniform mat4 u_worldViewProjectionMatrix;           // Matrix to transform a position to clip space.
uniform mat4 u_inverseTransposeWorldViewMatrix;     // Matrix to transform a normal to view space.
uniform mat4 u_worldViewMatrix;                     // Matrix to tranform a position to view space.
uniform vec3 u_cameraViewPosition;                      // Position of the camera in view space.
uniform vec3 u_cameraWorldPosition;



// Inputs
attribute vec4 a_position;                          // Vertex Position (x, y, z, w)
attribute vec3 a_normal;                            // Vertex Normal (x, y, z)
attribute vec2 a_texCoord;                          // Vertex Texture Coordinate (u, v)

// Outputs
varying vec3 v_normalVector;                        // NormalVector in view space.
varying vec2 v_texCoord;                            // Texture coordinate (u, v).
varying vec3 v_cameraDirection;                     // Camera direction


//refect coordinate
varying vec3 v_reflectCoord;


#ifdef MAXDIRLIGHT
struct DirectionLight
{
    vec3 dir;
    vec3 color;
};
#endif

#ifdef MAXPOINTLIGHT
struct PointLight
{
    vec3 position;
    vec3 color;
    float rangeInverse;
};
#endif

#ifdef MAXSPOTLIGHT
struct SpotLight
{
    vec3 position;
    vec3 color;
    float rangeInverse;
    vec3 dir;
    float innerAngleCos;
    float outerAngleCos;
};
#endif

#ifdef MAXDIRLIGHT
uniform DirectionLight u_dirlight[MAXDIRLIGHT];
#endif
#ifdef MAXPOINTLIGHT
uniform PointLight u_pointlight[MAXPOINTLIGHT];
#endif
#ifdef MAXSPOTLIGHT
uniform SpotLight u_spotlight[MAXSPOTLIGHT];
#endif

//uniform vec3 u_nlight; // light number, u_nlight.x directional light, u_nlight.y point light, u_nlight.z spot light
#ifdef OPENGL_ES
uniform lowp int u_ndirlight;
uniform lowp int u_npointlight;
uniform lowp int u_nspotlight;
#else
uniform int u_ndirlight;
uniform int u_npointlight;
uniform int u_nspotlight;
#endif

#ifdef MAXPOINTLIGHT
varying vec4 v_vertexToPointLightDirection[MAXPOINTLIGHT];
#endif
#ifdef MAXSPOTLIGHT
varying vec3 v_vertexToSpotLightDirection[MAXSPOTLIGHT];              // Light direction w.r.t current vertex.
varying float v_spotLightAttenuation[MAXSPOTLIGHT];                   // Attenuation of spot light.
#endif

#ifdef MAXPOINTLIGHT
void applyPointLight(vec4 position)
{
    vec4 positionWorldViewSpace = u_worldViewMatrix * position;

	v_cameraDirection = u_cameraViewPosition - positionWorldViewSpace.xyz;
    
    for (int i = 0; i < u_npointlight; i++)
	{
        vec3 lightDirection = u_pointlight[i].position - positionWorldViewSpace.xyz;
        
		vec4 vertexToPointLightDirection;
        vertexToPointLightDirection.xyz = lightDirection;
        
        // Attenuation
        vertexToPointLightDirection.w = 1.0 - dot(lightDirection * u_pointlight[i].rangeInverse, lightDirection * u_pointlight[i].rangeInverse);
        vertexToPointLightDirection.w = clamp(vertexToPointLightDirection.w, 0.0, 1.0);
        
		// Output light direction.
        v_vertexToPointLightDirection[i] =  vertexToPointLightDirection;
    }
}
#endif

#ifdef MAXSPOTLIGHT
void applySpotLight(vec4 position)
{
    // World space position.
    vec4 positionWorldViewSpace = u_worldViewMatrix * position;
	
    v_cameraDirection = u_cameraViewPosition - positionWorldViewSpace.xyz;
    
    for (int i = 0; i < u_nspotlight; i++)
	{
        // Compute the light direction with light position and the vertex position.
        vec3 lightDirection = u_spotlight[i].position - positionWorldViewSpace.xyz;
        
        // Attenuation
        v_spotLightAttenuation[i] = 1.0 - dot(lightDirection * u_spotlight[i].rangeInverse, lightDirection * u_spotlight[i].rangeInverse);
		v_spotLightAttenuation[i] = clamp(v_spotLightAttenuation[i], 0.0, 1.0);
        
        // Compute the light direction with light position and the vertex position.
        v_vertexToSpotLightDirection[i] = lightDirection;
    }
}
#endif

#ifdef MAXDIRLIGHT
void applyDirLight(vec4 position)
{
    vec4 positionWorldViewSpace = u_worldViewMatrix * position;
    v_cameraDirection = u_cameraViewPosition - positionWorldViewSpace.xyz;
}
#endif


void getReflect(vec4 position, vec3 normal)
{
	vec3 worldNormal = (u_inverseTransposeWorldViewMatrix * vec4(normal, 0.0)).xyz;
	worldNormal = normalize(worldNormal);
	
	vec4 pos = normalize(u_worldViewMatrix * position);
	pos = pos / pos.w;
	vec3 vEyeVertex = normalize(u_cameraWorldPosition - pos.xyz);
	
	vec4 vReflectCoord = vec4(reflect(-vEyeVertex, worldNormal), 1.0);
    
  v_reflectCoord = normalize(vReflectCoord.xyz);
}




#include "skinned_general.h"

void main()
{
    vec4 position = getPosition();
    vec3 normal = getNormal();

    // Transform position to clip space.
    gl_Position = u_worldViewProjectionMatrix * position;

    // Transform normal to view space.
    mat3 normalMatrix = mat3(u_inverseTransposeWorldViewMatrix[0].xyz,
                             u_inverseTransposeWorldViewMatrix[1].xyz,
                             u_inverseTransposeWorldViewMatrix[2].xyz);
    v_normalVector = normalMatrix * normal;

    // Compute the camera direction.
    vec4 positionWorldViewSpace = u_worldViewMatrix * position;
    v_cameraDirection = u_cameraViewPosition - positionWorldViewSpace.xyz;

    // Apply light.
    #ifdef MAXDIRLIGHT
    if (u_ndirlight > 0)
        applyDirLight(position);
    #endif
    
    #ifdef MAXPOINTLIGHT
    if (u_npointlight > 0)
        applyPointLight(position);
    #endif
    
    #ifdef MAXSPOTLIGHT
    if (u_nspotlight > 0)
        applySpotLight(position);
    #endif
    
    getReflect(position,normal);


	// Pass on the texture coordinates to Fragment shader.
    v_texCoord = a_texCoord;
}
