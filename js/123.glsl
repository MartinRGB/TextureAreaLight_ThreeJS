vec3 normal = normalize( vNormal );  
vec3 viewPosition = normalize( vViewPosition );   
#ifdef DOUBLE_SIDED    
normal = normal * ( -1.0 + 2.0 * float( gl_FrontFacing ) ); 
#endif   
#ifdef USE_NORMALMAP   
normal = perturbNormal2Arb( -viewPosition, normal );   
#elif defined( USE_BUMPMAP )   
normal = perturbNormalArb( -vViewPosition, normal, dHdxy_fwd() );  
#endif    
#if MAX_POINT_LIGHTS > 0    
vec3 pointDiffuse  = vec3( 0.0 );   
vec3 pointSpecular = vec3( 0.0 );  
for ( int i = 0; i < MAX_POINT_LIGHTS; i ++ ) {   
#ifdef PHONG_PER_PIXEL 
vec4 lPosition = viewMatrix * vec4( pointLightPosition[ i ], 1.0 );  
vec3 lVector = lPosition.xyz + vViewPosition.xyz; 
float lDistance = 1.0;   
if ( pointLightDistance[ i ] > 0.0 )   
lDistance = 1.0 - min( ( length( lVector ) / pointLightDistance[ i ] ), 1.0 ); 
lVector = normalize( lVector );  
#else 
vec3 lVector = normalize( vPointLight[ i ].xyz );    
float lDistance = vPointLight[ i ].w;   
#endif 
float dotProduct = dot( normal, lVector );   
#ifdef WRAP_AROUND 
float pointDiffuseWeightFull = max( dotProduct, 0.0 );   
float pointDiffuseWeightHalf = max( 0.5 * dotProduct + 0.5, 0.0 ); 
vec3 pointDiffuseWeight = mix( vec3 ( pointDiffuseWeightFull ), vec3( pointDiffuseWeightHalf ), wrapRGB );   
#else  
float pointDiffuseWeight = max( dotProduct, 0.0 );    
#endif  
pointDiffuse  += diffuse * pointLightColor[ i ] * pointDiffuseWeight * lDistance; 
vec3 pointHalfVector = normalize( lVector + viewPosition );  
float pointDotNormalHalf = max( dot( normal, pointHalfVector ), 0.0 );    
float pointSpecularWeight = specularStrength * max( pow( pointDotNormalHalf, shininess ), 0.0 );    
#ifdef PHYSICALLY_BASED_SHADING 
float specularNormalization = ( shininess + 2.0001 ) / 8.0;  
vec3 schlick = specular + vec3( 1.0 - specular ) * pow( 1.0 - dot( lVector, pointHalfVector ), 5.0 ); 
pointSpecular += schlick * pointLightColor[ i ] * pointSpecularWeight * pointDiffuseWeight * lDistance * specularNormalization;  
#else 
pointSpecular += specular * pointLightColor[ i ] * pointSpecularWeight * pointDiffuseWeight * lDistance; 
#endif   
}  
#endif    
#if MAX_SPOT_LIGHTS > 0 
vec3 spotDiffuse  = vec3( 0.0 ); 
vec3 spotSpecular = vec3( 0.0 ); 
for ( int i = 0; i < MAX_SPOT_LIGHTS; i ++ ) {   
#ifdef PHONG_PER_PIXEL 
vec4 lPosition = viewMatrix * vec4( spotLightPosition[ i ], 1.0 );   
vec3 lVector = lPosition.xyz + vViewPosition.xyz;  
float lDistance = 1.0;    
if ( spotLightDistance[ i ] > 0.0 ) 
lDistance = 1.0 - min( ( length( lVector ) / spotLightDistance[ i ] ), 1.0 );    
lVector = normalize( lVector ); 
#else    
vec3 lVector = normalize( vSpotLight[ i ].xyz );    
float lDistance = vSpotLight[ i ].w;    
#endif  
float spotEffect = dot( spotLightDirection[ i ], normalize( spotLightPosition[ i ] - vWorldPosition ) );  
if ( spotEffect > spotLightAngleCos[ i ] ) {  
spotEffect = max( pow( spotEffect, spotLightExponent[ i ] ), 0.0 );   
float dotProduct = dot( normal, lVector ); 
#ifdef WRAP_AROUND   
float spotDiffuseWeightFull = max( dotProduct, 0.0 );  
float spotDiffuseWeightHalf = max( 0.5 * dotProduct + 0.5, 0.0 ); 
vec3 spotDiffuseWeight = mix( vec3 ( spotDiffuseWeightFull ), vec3( spotDiffuseWeightHalf ), wrapRGB );  
#else 
float spotDiffuseWeight = max( dotProduct, 0.0 );    
#endif  
spotDiffuse += diffuse * spotLightColor[ i ] * spotDiffuseWeight * lDistance * spotEffect;    
vec3 spotHalfVector = normalize( lVector + viewPosition );  
float spotDotNormalHalf = max( dot( normal, spotHalfVector ), 0.0 );  
float spotSpecularWeight = specularStrength * max( pow( spotDotNormalHalf, shininess ), 0.0 );    
#ifdef PHYSICALLY_BASED_SHADING 
float specularNormalization = ( shininess + 2.0001 ) / 8.0;  
vec3 schlick = specular + vec3( 1.0 - specular ) * pow( 1.0 - dot( lVector, spotHalfVector ), 5.0 );  
spotSpecular += schlick * spotLightColor[ i ] * spotSpecularWeight * spotDiffuseWeight * lDistance * specularNormalization * spotEffect;  
#else 
spotSpecular += specular * spotLightColor[ i ] * spotSpecularWeight * spotDiffuseWeight * lDistance * spotEffect;    
#endif  
} 
}    
#endif  
#if MAX_DIR_LIGHTS > 0    
vec3 dirDiffuse  = vec3( 0.0 ); 
vec3 dirSpecular = vec3( 0.0 );  
for( int i = 0; i < MAX_DIR_LIGHTS; i ++ ) {  
vec4 lDirection = viewMatrix * vec4( directionalLightDirection[ i ], 0.0 );   
vec3 dirVector = normalize( lDirection.xyz );  
float dotProduct = dot( normal, dirVector );  
#ifdef WRAP_AROUND    
float dirDiffuseWeightFull = max( dotProduct, 0.0 );    
float dirDiffuseWeightHalf = max( 0.5 * dotProduct + 0.5, 0.0 );    
vec3 dirDiffuseWeight = mix( vec3( dirDiffuseWeightFull ), vec3( dirDiffuseWeightHalf ), wrapRGB ); 
#else    
float dirDiffuseWeight = max( dotProduct, 0.0 );    
#endif  
dirDiffuse  += diffuse * directionalLightColor[ i ] * dirDiffuseWeight;   
vec3 dirHalfVector = normalize( dirVector + viewPosition );    
float dirDotNormalHalf = max( dot( normal, dirHalfVector ), 0.0 );  
float dirSpecularWeight = specularStrength * max( pow( dirDotNormalHalf, shininess ), 0.0 );  
#ifdef PHYSICALLY_BASED_SHADING   
float specularNormalization = ( shininess + 2.0001 ) / 8.0;    
vec3 schlick = specular + vec3( 1.0 - specular ) * pow( 1.0 - dot( dirVector, dirHalfVector ), 5.0 );   
dirSpecular += schlick * directionalLightColor[ i ] * dirSpecularWeight * dirDiffuseWeight * specularNormalization;    
#else   
dirSpecular += specular * directionalLightColor[ i ] * dirSpecularWeight * dirDiffuseWeight;   
#endif 
}    
#endif  
#if MAX_HEMI_LIGHTS > 0   
vec3 hemiDiffuse  = vec3( 0.0 );   
vec3 hemiSpecular = vec3( 0.0 );   
for( int i = 0; i < MAX_HEMI_LIGHTS; i ++ ) {  
vec4 lDirection = viewMatrix * vec4( hemisphereLightDirection[ i ], 0.0 );    
vec3 lVector = normalize( lDirection.xyz ); 
float dotProduct = dot( normal, lVector );   
float hemiDiffuseWeight = 0.5 * dotProduct + 0.5;  
vec3 hemiColor = mix( hemisphereLightGroundColor[ i ], hemisphereLightSkyColor[ i ], hemiDiffuseWeight ); 
hemiDiffuse += diffuse * hemiColor;  
vec3 hemiHalfVectorSky = normalize( lVector + viewPosition ); 
float hemiDotNormalHalfSky = 0.5 * dot( normal, hemiHalfVectorSky ) + 0.5;   
float hemiSpecularWeightSky = specularStrength * max( pow( hemiDotNormalHalfSky, shininess ), 0.0 );   
vec3 lVectorGround = -lVector; 
vec3 hemiHalfVectorGround = normalize( lVectorGround + viewPosition );   
float hemiDotNormalHalfGround = 0.5 * dot( normal, hemiHalfVectorGround ) + 0.5;   
float hemiSpecularWeightGround = specularStrength * max( pow( hemiDotNormalHalfGround, shininess ), 0.0 ); 
#ifdef PHYSICALLY_BASED_SHADING  
float dotProductGround = dot( normal, lVectorGround );    
float specularNormalization = ( shininess + 2.0001 ) / 8.0; 
vec3 schlickSky = specular + vec3( 1.0 - specular ) * pow( 1.0 - dot( lVector, hemiHalfVectorSky ), 5.0 );   
vec3 schlickGround = specular + vec3( 1.0 - specular ) * pow( 1.0 - dot( lVectorGround, hemiHalfVectorGround ), 5.0 ); 
hemiSpecular += hemiColor * specularNormalization * ( schlickSky * hemiSpecularWeightSky * max( dotProduct, 0.0 ) + schlickGround * hemiSpecularWeightGround * max( dotProductGround, 0.0 ) );   
#else  
hemiSpecular += specular * hemiColor * ( hemiSpecularWeightSky + hemiSpecularWeightGround ) * hemiDiffuseWeight;  
#endif    
}   
#endif 
#if MAX_AREA_LIGHTS > 0  
vec3 areaDiffuse  = vec3( 0.0 );  
vec3 areaSpecular = vec3( 0.0 );  
for( int i = 0; i < MAX_AREA_LIGHTS; i ++ ) { 
float w = areaLightSize[ i ].x;  
float h = areaLightSize[ i ].y;   
vec3 vertexPosition = -vViewPosition.xyz;  
vec3 proj = projectOnPlane( vertexPosition, areaLightPosition[ i ], areaLightNormal[ i ] );   
vec3 dir = proj - areaLightPosition[ i ];  
vec2 diagonal = vec2( dot( dir, areaLightRight[ i ] ), dot( dir, areaLightUp[ i ] ) );    
vec2 nearest2D = vec2( clamp( diagonal.x, -w, w ), clamp( diagonal.y, -h, h ) );    
vec3 nearestPointInside = areaLightPosition[ i ] + ( areaLightRight[ i ] * nearest2D.x + areaLightUp[ i ] * nearest2D.y );  
vec3 lightDir = normalize( nearestPointInside - vertexPosition ); 
float NdotL = max( dot( areaLightNormal[ i ], -lightDir ), 0.0 );    
float NdotL2 = max( dot( normal, lightDir ), 0.0 ); 
vec3 areaDiffuseWeight = vec3( sqrt( NdotL * NdotL2 ) ); 
float dist = distance( vertexPosition, nearestPointInside ); 
float attenuation = calculateAttenuation( dist, areaLightAttenuation[ i ].x, areaLightAttenuation[ i ].y, areaLightAttenuation[ i ].z ); 
vec3 areaDiffuseTerm = diffuse * areaDiffuseWeight * areaLightColor[ i ] * attenuation;  
#ifdef AREA_TEXTURE   
if ( areaLightSize[ i ].z > 0.0 ) {    
float d = distance( vertexPosition, nearestPointInside );   
vec2 co = ( diagonal.xy + vec2( w, h ) ) / ( 2.0 * vec2( w, h ) ); 
co.y = 1.0 - co.y;   
vec3 ve = vertexPosition - areaLightPosition[ i ]; 
vec4 diff = vec4( 0.0 ); 
if ( dot( ve, areaLightNormal[ i ] ) < 0.0 ) {   
diff = vec4( 0.0 );    
} else {    
float lod = max( pow( d, 0.1 ), 0.0 ) * 5.0;    
vec4 t00 = texture2D( areaLightTexture[ i ], co, lod ); 
vec4 t01 = texture2D( areaLightTexture[ i ], co, lod + 1.0 );    
diff = mix( t00, t01, 0.5 );    
}   
areaDiffuseTerm *= diff.xyz;   
}  
#endif    
areaDiffuse += areaDiffuseTerm; 
vec3 R = reflect( normalize( -vertexPosition ), normal );    
vec3 E = linePlaneIntersect( vertexPosition, R, areaLightPosition[ i ], areaLightNormal[ i ] ); 
float specAngle = dot( R, areaLightNormal[ i ] );    
if ( dot( vertexPosition - areaLightPosition[ i ], areaLightNormal[ i ] ) >= 0.0 && specAngle > 0.0 ) { 
vec3 dirSpec = E - areaLightPosition[ i ];   
vec2 dirSpec2D = vec2( dot( dirSpec, areaLightRight[ i ] ), dot( dirSpec, areaLightUp[ i ] ) );    
vec2 nearestSpec2D = vec2( clamp( dirSpec2D.x, -w, w ), clamp( dirSpec2D.y, -h, h ) );  
float specFactor = 1.0 - clamp( length( nearestSpec2D - dirSpec2D ) * 0.05 * shininess, 0.0, 1.0 );   
vec3 areaSpecularWeight = specFactor * specAngle * areaDiffuseWeight;  
vec3 areaSpecularTerm = specular * areaSpecularWeight * areaLightColor[ i ] * attenuation;    
#ifdef AREA_TEXTURE 
if ( areaLightSize[ i ].z > 0.0 ) {  
float hard = 16.0;    
float gloss = 16.0; 
vec3 specPlane = areaLightPosition[ i ] + ( areaLightRight[ i ] * dirSpec2D.x + areaLightUp[ i ] * dirSpec2D.y );    
float dist = max( distance( vertexPosition, specPlane ), 0.0 ); 
float d = ( ( 1.0 / hard ) / 2.0 ) * ( dist / gloss );   
w = max( w, 0.0 ); 
h = max( h, 0.0 );   
vec2 co = dirSpec2D / ( d + 1.0 ); 
co /= 2.0 * vec2( w, h );    
co = co + vec2( 0.5 );  
co.y = 1.0 - co.y;    
float lod = ( 2.0 / hard * max( dist, 0.0 ) );  
vec4 t00 = texture2D( areaLightTexture[ i ], co, lod );   
vec4 t01 = texture2D( areaLightTexture[ i ], co, lod + 1.0 );  
vec4 spec = mix( t00, t01, 0.5 ); 
areaSpecularTerm *= spec.xyz;    
}   
#endif 
areaSpecular += areaSpecularTerm;    
}   
}  
#endif    
vec3 totalDiffuse = vec3( 0.0 );    
vec3 totalSpecular = vec3( 0.0 );   
#if MAX_DIR_LIGHTS > 0 
totalDiffuse += dirDiffuse;  
totalSpecular += dirSpecular; 
#endif   
#if MAX_HEMI_LIGHTS > 0    
totalDiffuse += hemiDiffuse;    
totalSpecular += hemiSpecular;  
#endif    
#if MAX_POINT_LIGHTS > 0    
totalDiffuse += pointDiffuse;   
totalSpecular += pointSpecular;    
#endif  
#if MAX_SPOT_LIGHTS > 0   
totalDiffuse += spotDiffuse;   
totalSpecular += spotSpecular; 
#endif   
#if MAX_AREA_LIGHTS > 0    
totalDiffuse += areaDiffuse;    
totalSpecular += areaSpecular;  
#endif    
#ifdef METAL    
gl_FragColor.xyz = gl_FragColor.xyz * ( emissive + totalDiffuse + ambientLightColor * ambient + totalSpecular );    
#else   
gl_FragColor.xyz = gl_FragColor.xyz * ( emissive + totalDiffuse + ambientLightColor * ambient ) + totalSpecular;   
#endif",