
Shader "Test/FragmentLambert"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Tint("Color", Color) = (0,1,0,1)
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32
    }
        SubShader
    {
        Pass
        {
            Tags {"Queue" = "Transparent" "RenderType" = "Transparent" "LightMode" = "ForwardBase"}

            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

         #pragma vertex vert
         #pragma fragment frag
         # include "UnityCG.cginc"
         # include "Lighting.cginc"
        // # include "UnityLightingCommon.cginc"       
         #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
         # include "AutoLight.cginc"

            struct v2f
           {
                float2 uv : TEXCOORD0;
               SHADOW_COORDS(1) // put shadows data into TEXCOORD1
               float3 viewDir : TEXCOORD2;
                fixed3 diff : COLOR0;
                fixed3 ambient : COLOR1;
                float4 pos : SV_POSITION;
                half3 worldNormal : NORMAL;
            };

          v2f vert(appdata_base v)
           {
             v2f o;
             o.pos = UnityObjectToClipPos(v.vertex);
             o.uv = v.texcoord;
             o.worldNormal = UnityObjectToWorldNormal(v.normal);
             half nl = max(0, dot(o.worldNormal, _WorldSpaceLightPos0.xyz));
             o.diff = nl * _LightColor0.rgb;
             //o.diff.rgb += ShadeSH9(half4(worldNormal, 1));  
             o.ambient = ShadeSH9(half4(o.worldNormal, 1));

             // compute shadows data
             TRANSFER_SHADOW(o)

             o.viewDir = WorldSpaceViewDir(v.vertex);
             return o;
             }

               sampler2D _MainTex;
               fixed4 _Tint;
               fixed4 _SpecularColor;
               float _Glossiness;

        fixed4 frag(v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv) * _Tint;
            // compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
            fixed shadow = SHADOW_ATTENUATION(i);
            // darken light's illumination with shadow, keep ambient intact
            fixed3 lighting = i.diff;// * shadow + i.ambient;

            fixed bandNum = 2.0f;
            fixed3 bandedDiffuse = ceil(lighting * bandNum) / bandNum;

            fixed3 viewDir = normalize(i.worldNormal);
            fixed3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);

            fixed NdotH = dot(i.worldNormal, halfVector);

            fixed specularIntensity = pow(NdotH * lighting, _Glossiness * _Glossiness);

            col.rgb = col.rgb + specularIntensity + shadow + i.ambient;

            return col;
           }
           ENDCG
       }
        // shadow casting support
        // UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
        // Shadow pass를 추가하지 않고 이렇게 UsePass도 대체할수 있다.

      Pass
      {

        Tags { "LightMode" = "ShadowCaster"}

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcaster
        # include "UnityCG.cginc"

           struct v2f
          {
        V2F_SHADOW_CASTER;
          };

        v2f vert(appdata_base v)
          {

           v2f o;
          TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

          return o;
       }

         float4 frag(v2f i) : SV_Target
              {
                SHADOW_CASTER_FRAGMENT(i)
              }

              ENDCG
          }

    }
}