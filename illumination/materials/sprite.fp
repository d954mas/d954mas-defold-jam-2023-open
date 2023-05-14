uniform lowp sampler2D DIFFUSE_TEXTURE;

uniform lowp vec4 fog;
uniform lowp vec4 fog_color;
uniform lowp vec4 ambient_color;
uniform lowp vec4 sunlight_color;
uniform lowp vec4 sunlight_direction;

uniform highp vec4 surface;

varying mediump vec2 var_texcoord0;
varying highp vec3 var_camera_position;
varying highp vec3 var_world_position;
varying highp vec3 var_view_position;
varying mediump vec3 var_world_normal;

#define LIGHT_COUNT 32

//number
uniform mediump vec4 lights;
//x,y,z
uniform mediump vec4 lights_position[LIGHT_COUNT];
//x,y,z
uniform mediump vec4 lights_direction[LIGHT_COUNT];

//rgb power
uniform lowp vec4 lights_color[LIGHT_COUNT];
//radius smoothness cutoff
uniform mediump vec4 lights_data1[LIGHT_COUNT];


uniform lowp vec4 tint;



void main() {
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);

    vec4 texture_color = texture2D(DIFFUSE_TEXTURE, var_texcoord0)* tint_pm;
    if (texture_color.a < 0.1) {
        discard;
    }


    vec3 color = texture_color.rgb;

    //
    // Defold Editor

   /* vec4 meta_1 = get_data(0.0);
    if (meta_1.r == 0.0) {
        vec3 editor_ambient = vec3(0.8);
        vec3 editor_diffuse = vec3(1.0) - editor_ambient;

        editor_diffuse = editor_ambient + editor_diffuse * var_world_normal.y;

        gl_FragColor = vec4(color.rgb * editor_diffuse.rgb, 1.0);

        // If the first byte is zero, it's the editor,
        // so just shade the sides according to the normal.
        return;
    }*/


    // Fog
    float distance = abs(var_view_position.z);
    //float distance = length(var_view_position);
    float fog_min = fog.x;
    float fog_max = fog.y;
    float fog_intensity = fog.w;
    float fog_factor = (1.0 - clamp((fog_max - distance) / (fog_max - fog_min), 0.0, 1.0)) * fog_intensity;


    //COLOR
    vec3 illuminance_color = vec3(0);

    // Directional light
    float diff_directional_light = max(dot(var_world_normal, normalize(sunlight_direction.xyz)), 0.0) *  sunlight_color.w;
    vec3 directional_light =  diff_directional_light * sunlight_color.rgb;

    // Ambient
    vec3 ambient = ambient_color.rgb * ambient_color.w;
    illuminance_color = illuminance_color + ambient+directional_light;


    //
    // Lights

   // vec4 meta_1 = get_data(0.0);
    int lights_count = int(lights.x);
    for(int i=0;i<lights_count;i++){
        vec3 light_position = lights_position[i].xyz;
        vec3 spot_direction = lights_direction[i].xyz;
        vec4 light_color0 = lights_color[i];
        vec4 light_data = lights_data1[i];
        float light_radius = light_data.x;

        float light_distance = length(light_position - var_world_position);
        if (light_distance > light_radius) {
            // Skip this light source because of distance
            continue;
        }
        vec3 light_direction = normalize(light_position - var_world_position);
        vec3 light_color = light_color0.rgb * light_color0.w;
        float light_smoothness = light_data.y;
        float spot_cutoff = light_data.z;


        vec3 light_illuminance_color = light_color;
        float light_attenuation = pow(clamp(1.0 - light_distance / light_radius, 0.0, 1.0), 2.0 * light_smoothness);
        float light_strength = light_attenuation * max(dot(var_world_normal, light_direction), 0.0);

        if(spot_cutoff<1.0){
            float spot_theta = dot(light_direction, normalize(spot_direction));
            if (spot_theta <= spot_cutoff) {
                continue;
            }
            if (light_smoothness > 0.0) {
                float spot_cutoff_inner = (spot_cutoff + 1.0) * (1.0 - light_smoothness) - 1.0;
                float spot_epsilon = spot_cutoff_inner - spot_cutoff;
                float spot_intensity = clamp((spot_cutoff - spot_theta) / spot_epsilon, 0.0, 1.0);

                light_illuminance_color = light_illuminance_color * spot_intensity;
            }
        }
        illuminance_color = illuminance_color + light_illuminance_color * light_strength;

    }



    vec3 diff_light = vec3(0);
    diff_light += vec3(illuminance_color.xyz);
    // diff_light = clamp(diff_light, 0.0, ambient_color.w);

    color.rgb = color.rgb * (min(diff_light, 1.0));
    //color.rgb = illuminance_color.rgb;
    //endregion


    //
    // Mixing
    // color = color * (min(illuminance_color, 1.0));
    color = mix(color, fog_color.rgb, fog_factor);

    gl_FragColor = vec4(color, texture_color.a);

}