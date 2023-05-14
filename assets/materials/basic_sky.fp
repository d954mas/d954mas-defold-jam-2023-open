#define pi 3.1415926535897932384626433832795
#define light_pixels_count 5.0
#define meta_pixels_count 5.0
#define texture_size 32.0

uniform highp vec4 surface;

varying highp vec3 camera_position;
varying highp vec3 world_position;
varying highp vec3 view_position;
varying mediump vec3 world_normal;
varying mediump vec2 texture_coord;
varying mediump vec2 light_map_coord;


uniform lowp sampler2D DIFFUSE_TEXTURE;
uniform lowp sampler2D DATA_TEXTURE;

vec4 get_data(float index) {
    float x = mod(index, texture_size) / texture_size;
    float y = float(index / texture_size) / float(texture_size);

    return texture2D(DATA_TEXTURE, vec2(x, y));
}

float get_fog_factor(float distance, float fog_min, float fog_max) {
    if (distance >= fog_max) {
        return 1.0;
    }

    if (distance <= fog_min) {
        return 0.0;
    }

    return 1.0 - (fog_max - distance) / (fog_max - fog_min);
}

void main(){
    // Texture
    vec4 texture_color = texture2D(DIFFUSE_TEXTURE, texture_coord);

    vec3 color = texture_color.rgb;
    vec3 view_direction = normalize(camera_position - world_position);
    vec3 surface_normal = world_normal;

    vec4 meta_1 = get_data(0.0);



     vec3 illuminance_color = vec3(0.5);

    //
    // Ambient

    vec4 meta_2 = get_data(1.0);
    vec3 ambient_color = meta_2.rgb * meta_2.w;

    illuminance_color = illuminance_color + ambient_color;


    //
    // Sunlight

    vec4 meta_3 = get_data(2.0);

    if (meta_3.a > 0.0) {
        vec4 meta_4 = get_data(3.0);

        //vec3 sunlight_direction = meta_4.rgb * 2.0 - vec3(1.0);
      //  float sunlight_shininess = max(dot(surface_normal, sunlight_direction), 0.0);
        vec3 sunlight_color = meta_3.rgb * meta_3.w * 1.0;

        float sunlight_specular = meta_4.a;
       // vec3 sunlight_specular_color = get_specular_color(specular_map_color, sunlight_specular, sunlight_color, sunlight_direction, surface_normal, view_direction);

        illuminance_color = illuminance_color + sunlight_color;
       // specular_color = specular_color + sunlight_specular_color;
    }

    color = color * (min(illuminance_color, 1.0));
   // color = (min(color + specular_map_color.x * specular_color, 1.0));
    //color = mix(color, fog_color.rgb, fog_color.a);

    gl_FragColor = vec4(color.rgb, texture_color.a);
}
