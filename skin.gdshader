shader_type spatial;

uniform sampler2D skin;

void vertex() {
// Output:0
}

void fragment() {
// Texture:2
	vec4 tex_frg_2_read = texture(skin, UV.xy);
	vec3 n_out2p0 = tex_frg_2_read.rgb;
	float n_out2p1 = tex_frg_2_read.a;

// Output:0
	ALBEDO = n_out2p0;
}

void light() {
// Output:0
}