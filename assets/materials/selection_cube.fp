varying highp vec3 var_world_position;
varying mediump vec3 var_world_normal;
varying highp vec3 var_position;
varying mediump vec3 var_normal;
varying highp vec2 var_texcoord0;

uniform lowp sampler2D texture0;

void main()
{

    vec4 overlay_color = texture2D(texture0, var_texcoord0.xy);

    if(overlay_color.a < 0.01){
        discard;
    }
    // Color + Fog
    gl_FragColor = overlay_color;
}

