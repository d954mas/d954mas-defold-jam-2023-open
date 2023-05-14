#define pi 3.1415926535897932384626433832795
#define light_pixels_count 5.0
#define meta_pixels_count 5.0
#define texture_size 32.0

const highp float axis_capacity = 2.0 * 2048.0;
const highp float max_uint24 = 256.0 * 256.0 * 256.0 - 1.0;
const highp vec3 flat_normal = vec3(0.5, 0.5, 1.0);


uniform lowp sampler2D DIFFUSE_TEXTURE;
uniform lowp sampler2D DATA_TEXTURE;

uniform lowp vec4 fog;
uniform lowp vec4 fog_color;
uniform lowp vec4 ambient_color;


//region shadow
uniform lowp sampler2D SHADOW_TEXTURE;
uniform highp vec4 cam_pos;
uniform lowp vec4 sunlight_color;
uniform highp vec4 light;
uniform highp vec4 shadow_color;
uniform lowp vec4 ambient;
//endregion


uniform highp vec4 surface;


varying mediump vec2 var_texcoord0;
varying mediump vec4 var_uvSize;
varying mediump vec2 var_uvToCenter;
varying mediump vec2 var_tiles;
varying lowp float var_light_power;

varying highp vec3 var_camera_position;
varying highp vec3 var_world_position;
varying highp vec3 var_view_position;
varying mediump vec3 var_world_normal;

//region shadow
varying highp vec4 var_texcoord0_shadow;
//endregion

//region shadow ----------------------------------------------


vec2 rand(vec2 co)
{
    return vec2(fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453),
    fract(sin(dot(co.yx, vec2(12.9898, 78.233))) * 43758.5453)) * 0.00047;
}
float shadow_calculation(vec4 depth_data)
{
    float depth_bias = 0.0008;
    float shadow = 0.0;
    float texel_size = 1.0 / 2048.0;//textureSize(SHADOW_TEXTURE, 0);
    for (int x = -1; x <= 1; ++x)
    {
        for (int y = -1; y <= 1; ++y)
        {
            vec2 uv = depth_data.st + vec2(x, y) * texel_size;
            vec4 rgba = texture2D(SHADOW_TEXTURE, uv + rand(uv));
            // vec4 rgba = texture2D(SHADOW_TEXTURE, uv);
            // float depth = rgba_to_float(rgba);
            float depth = rgba.x;
            shadow += depth_data.z - depth_bias > depth ? 1.0 : 0.0;
        }
    }
    shadow /= 9.0;

    highp vec2 uv = depth_data.xy;
    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}

float shadow_calculation_mobile(vec4 depth_data)
{
    float depth_bias = 0.0008;
    highp vec2 uv = depth_data.xy;
    // vec4 rgba = texture2D(SHADOW_TEXTURE, uv + rand(uv));
    vec4 rgba = texture2D(SHADOW_TEXTURE, uv);
    // float depth = rgba_to_float(rgba);
    float depth = rgba.x;
    float shadow = depth_data.z - depth_bias > depth ? 1.0 : 0.0;

    if (uv.x<0.0) shadow = 0.0;
    if (uv.x>1.0) shadow = 0.0;
    if (uv.y<0.0) shadow = 0.0;
    if (uv.y>1.0) shadow = 0.0;

    return shadow;
}

// SUN! DIRECT LIGHT
vec3 direct_light(vec3 light_color, vec3 light_position, vec3 position, vec3 vnormal, vec3 shadow_color)
{
    vec3 dist = light_position;
    vec3 direction = normalize(dist);
    float n = max(dot(vnormal, direction), 0.0);
    vec3 diffuse = (light_color - shadow_color) * n;
    return diffuse;
}

//endregion ----------------------------------------------------


// Does not take into account GL_TEXTURE_MIN_LOD/GL_TEXTURE_MAX_LOD/GL_TEXTURE_LOD_BIAS,
// nor implementation-specific flexibility allowed by OpenGL spec
float mip_map_level(in vec2 texture_coordinate)// in texel units
{
    vec2  dx_vtc        = dFdx(texture_coordinate);
    vec2  dy_vtc        = dFdy(texture_coordinate);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
    float mml = 0.5 * log2(delta_max_sqr);
    return max(0.0, mml);// Thanks @Nims
}

vec4 get_data(float index) {
    float x = mod(index, texture_size) / texture_size;
    float y = float(index / texture_size) / float(texture_size);

    return texture2D(DATA_TEXTURE, vec2(x, y));
}

float data_to_axis(vec3 data) {
    float r = 255.0 * data.r * 256.0 * 256.0;
    float g = 255.0 * data.g * 256.0;
    float b = 255.0 * data.b;
    float value = r + g + b;

    value = value - (max_uint24 * 0.5);
    value = value * (axis_capacity / max_uint24);

    return value;
}

mat3 get_tbn_mtx(vec3 normal, vec3 view_direction, vec2 texture_coord) {
    vec3 d_vd_x = dFdx(view_direction);
    vec2 d_tc_x = dFdx(texture_coord);

    #ifdef GL_ES
    vec3 d_vd_y = dFdy(-view_direction);
    vec2 d_tc_y = dFdy(-texture_coord);
    #else
    vec3 d_vd_y = dFdy(view_direction);
    vec2 d_tc_y = dFdy(texture_coord);
    #endif


    vec3 d_vd_y_cross = cross(d_vd_y, normal);
    vec3 d_vd_x_cross = cross(normal, d_vd_x);

    vec3 tangent = d_vd_y_cross * d_tc_x.x + d_vd_x_cross * d_tc_y.x;
    vec3 bitangent = d_vd_y_cross * d_tc_x.y + d_vd_x_cross * d_tc_y.y;

    float inv_max = inversesqrt(max(dot(tangent, tangent), dot(bitangent, bitangent)));
    mat3 tbn_mtx = mat3(tangent * inv_max, bitangent * inv_max, normal);

    return tbn_mtx;
}


void main(){
    vec2 texCoord = fract(var_texcoord0.xy*var_tiles);
    //https://stackoverflow.com/questions/34951491/using-floor-function-in-glsl-when-sampling-a-texture-leaves-glitch
    vec2 uvMipmap = var_uvSize.xy + var_texcoord0.xy*var_uvSize.zw;

    texCoord = var_uvSize.xy + (texCoord.xy*var_uvSize.zw);
    // convert normalized texture coordinates to texel units before calling mip_map_level
    //float mipmapLevel = mip_map_level(uvMipmap * vec2(textureSize(DIFFUSE_TEXTURE, 0).xy));
  //  mipmapLevel = clamp(mipmapLevel, 0.0, 3.0);
    //fixed mipmap bleeding
  //  vec4 texture_color = texture2D(DIFFUSE_TEXTURE, texCoord.xy+var_uvToCenter*mipmapLevel/3.0);
    vec4 texture_color = texture2D(DIFFUSE_TEXTURE, texCoord.xy);
   // vec4 texture_color =textureGrad(DIFFUSE_TEXTURE, texCoord+var_uvToCenter*mipmapLevel/3.0, dFdx(uvMipmap), dFdy(uvMipmap));
   // vec4 texture_color =textureGrad(DIFFUSE_TEXTURE, texCoord+var_uvToCenter*mipmapLevel/3.0, dFdx(uvMipmap), dFdy(uvMipmap));

    vec3 color = texture_color.rgb;
    color = color* var_light_power;//add AO


    // Fog
    float distance = abs(var_view_position.z);
    //float distance = length(var_view_position);
    float fog_min = fog.x;
    float fog_max = fog.y;
    float fog_intensity = fog.w;
    float fog_factor = (1.0 - clamp((fog_max - distance) / (fog_max - fog_min), 0.0, 1.0)) * fog_intensity;


    //COLOR
    vec3 illuminance_color = vec3(0);
    // Ambient
    vec3 ambient = ambient_color.rgb * ambient_color.w;
    illuminance_color = illuminance_color + ambient;


    //
    // Lights

    vec4 meta_1 = get_data(0.0);
    float lights_count = meta_1.r * 255.0 - 1.0;

    for (float p = meta_pixels_count; p < meta_pixels_count + lights_count * light_pixels_count; p = p + light_pixels_count) {
        vec4 light_2 = get_data(p + 1.0);
        vec4 light_3 = get_data(p + 2.0);
        vec4 light_4 = get_data(p + 3.0);

        float light_radius = light_2.r * 255.0;

        vec3 light_position = vec3(
        data_to_axis(vec3(light_2.a, light_3.rg)),
        data_to_axis(vec3(light_3.ba, light_4.r)),
        data_to_axis(light_4.gba)
        );

        float light_distance = length(light_position - var_world_position);

        if (light_distance > light_radius) {
            // Skip this light source because of distance
            continue;
        }

        vec4 light_1 = get_data(p);
        vec4 light_5 = get_data(p + 4.0);

        vec3 light_direction = normalize(light_position - var_world_position);
        vec3 light_color = light_1.rgb * light_1.w;
        float light_smoothness = light_2.g;

        vec3 light_illuminance_color = light_color;

        //
        // Attenuation

        float light_attenuation = pow(clamp(1.0 - light_distance / light_radius, 0.0, 1.0), 2.0 * light_smoothness);
        float light_strength = light_attenuation * max(dot(var_world_normal, light_direction), 0.0);

        //
        // Cutoff

        if (light_5.r < 1.0) {
            vec3 spot_direction = light_5.gba * 2.0 - vec3(1.0);
            float spot_theta = dot(light_direction, normalize(spot_direction));

            float spot_cutoff = light_5.r * 2.0 - 1.0;

            if (spot_theta <= spot_cutoff) {
                // Skip this light source because of cutoff
                continue;
            }

            if (light_smoothness > 0.0) {
                float spot_cutoff_inner = (spot_cutoff + 1.0) * (1.0 - light_smoothness) - 1.0;
                float spot_epsilon = spot_cutoff_inner - spot_cutoff;
                float spot_intensity = clamp((spot_cutoff - spot_theta) / spot_epsilon, 0.0, 1.0);

                light_illuminance_color = light_illuminance_color * spot_intensity;
            }
        }

        //
        // Adding

        illuminance_color = illuminance_color + light_illuminance_color * light_strength;
    }


    //REGION SHADOW -----------------
    vec3 normal_sum = var_world_normal;// no mormal map
    // shadow map
    vec4 depth_proj = var_texcoord0_shadow / var_texcoord0_shadow.w;
    float shadow = shadow_calculation(depth_proj.xyzw);
    vec3 shadow_color = shadow_color.xyz*shadow_color.w*(sunlight_color.w) * shadow;

    vec3 diff_light = vec3(0);
    diff_light += max(direct_light(sunlight_color.rgb, light.xyz, var_world_position.xyz, normal_sum, shadow_color)*sunlight_color.w,0.0);
    diff_light += vec3(illuminance_color.xyz);
    // diff_light = clamp(diff_light, 0.0, ambient_color.w);

    color.rgb = color.rgb * (min(diff_light, 1.0));

    //endregion


    //
    // Mixing
   // color = color * (min(illuminance_color, 1.0));
    color = mix(color, fog_color.rgb, fog_factor);

    gl_FragColor = vec4(color, texture_color.a);
}

