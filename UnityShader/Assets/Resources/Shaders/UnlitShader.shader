
Shader "Test/FragmentLambert"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Tint("Color", Color) = (0,1,0,1)
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32
        [HDR]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0,1)) = 0.716
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
         #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
         # include "UnityCG.cginc"
         # include "Lighting.cginc"
        // # include "UnityLightingCommon.cginc"       
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
             half nl = dot(o.worldNormal, _WorldSpaceLightPos0.xyz);
             o.diff = nl * normalize(_LightColor0.rgb);
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
               fixed _Glossiness;
               fixed4 _RimColor;
               fixed _RimAmount;

        fixed4 frag(v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv) * _Tint;

            fixed3 normal = normalize(i.worldNormal);

            // compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
            fixed shadow = SHADOW_ATTENUATION(i);
            // darken light's illumination with shadow, keep ambient intact
            fixed3 lighting = i.diff;// * shadow + i.ambient;

            fixed NDotL = dot(_WorldSpaceLightPos0.xyz, normal);
            fixed lightIntensity = smoothstep(0, 0.01, NDotL * shadow);
            fixed3 light = lightIntensity * _LightColor0;
            //fixed bandNum = 2.0 * 0.5;
            //fixed3 bandedDiffuse = ceil(lighting * bandNum) / bandNum * _LightColor0;

            fixed3 viewDir = normalize(i.viewDir);
            fixed3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
            fixed NdotH = dot(normal, halfVector);

            fixed specularIntensity = smoothstep(0.005, 0.01, pow(NdotH * lightIntensity, _Glossiness * _Glossiness));
            fixed4 specular = specularIntensity * _SpecularColor;

            fixed4 rimDot = 1 - dot(viewDir, normal);
            //fixed rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimDot);
            //fixed4 rim = rimIntensity * _RimColor;

            //fixed rimIntensity = NDotL * rimDot;

            //fixed rimIntensity = normalize(rimDot) * pow(NDotL * NDotL, _RimAmount);
            fixed rimIntensity = rimDot * pow(NDotL, _RimAmount);
            rimIntensity = smoothstep(0, +0.01, rimIntensity);
            fixed4 rim = rimIntensity * _RimColor;

            col.rgb = col.rgb * (light + i.ambient + specular + rim);

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