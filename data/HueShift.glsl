#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER
#define PI 3.14159265

const vec2 ANGLE0 = vec2(-1, -1);
const vec2 ANGLE1 = vec2(0, -1);
const vec2 ANGLE2 = vec2(1, -1);

const vec2 ANGLE3 = vec2(-1, 0);
const vec2 ANGLE4 = vec2(0, 0);
const vec2 ANGLE5 = vec2(1, 0);

const vec2 ANGLE6 = vec2(-1, 1);
const vec2 ANGLE7 = vec2(0, 1);
const vec2 ANGLE8 = vec2(1, 1);


uniform sampler2D texture;
uniform vec2 texOffset;
uniform float a;
uniform float t;
uniform float _t;
uniform sampler2D prevFrame;
uniform float Z1x;
uniform float Z1y;
uniform float Z2x;
uniform float Z2y;
uniform float Z3x;
uniform float Z3y;
uniform float mx;
uniform float my;
uniform float warpScale;
uniform float warpGrain;

//uniform float faceX;
//uniform float faceY;
//uniform float faceRadius;

//uniform float[9] conMatrix;
//uniform float conWeight;
//uniform vec2 flowDir;
//uniform float strength;

varying vec4 vertColor;
varying vec4 vertTexCoord;

vec2 noise(vec2 n) {
    vec2 ret;
    ret.x=fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 33758.5453)*2.0-1.0;
    ret.y=fract(sin(dot(n.xy, vec2(34.9865, 65.946)))* 28618.3756)*2.0-1.0;
    return normalize(ret);
}

float perlin(vec2 p) {
    vec2 q=floor(p);
    vec2 r=fract(p);
    float s=dot(noise(q),p-q);
    float t=dot(noise(vec2(q.x+1.0,q.y)),p-vec2(q.x+1.0,q.y));
    float u=dot(noise(vec2(q.x,q.y+1.0)),p-vec2(q.x,q.y+1.0));
    float v=dot(noise(vec2(q.x+1.0,q.y+1.0)),p-vec2(q.x+1.0,q.y+1.0));
    float Sx=3.0*(r.x*r.x)-2.0*(r.x*r.x*r.x);
    float a=s+Sx*(t-s);
    float b=u+Sx*(v-u);
    float Sy=3.0*(r.y*r.y)-2.0*(r.y*r.y*r.y);
    return a+Sy*(b-a);
}

float permute(float x0,vec3 p) { 
    float x1 = mod(x0 * p.y, p.x);
    return floor(  mod( (x1 + p.z) *x0, p.x ));
}
vec2 permute(vec2 x0,vec3 p) { 
    vec2 x1 = mod(x0 * p.y, p.x);
    return floor(  mod( (x1 + p.z) *x0, p.x ));
}
vec3 permute(vec3 x0,vec3 p) { 
    vec3 x1 = mod(x0 * p.y, p.x);
    return floor(  mod( (x1 + p.z) *x0, p.x ));
}
vec4 permute(vec4 x0,vec3 p) { 
    vec4 x1 = mod(x0 * p.y, p.x);
    return floor(  mod( (x1 + p.z) *x0, p.x ));
}

//uniform vec4 pParam; 
// Example constant with a 289 element permutation
const vec4 pParam = vec4( 17.0*17.0, 34.0, 1.0, 7.0);

float taylorInvSqrt(float r)
{ 
    return ( 0.83666002653408 + 0.7*0.85373472095314 - 0.85373472095314 * r );
}

float simplexNoise2(vec2 v)
{
    const vec2 C = vec2(0.211324865405187134, // (3.0-sqrt(3.0))/6.;
                        0.366025403784438597); // 0.5*(sqrt(3.0)-1.);
    const vec3 D = vec3( 0., 0.5, 2.0) * 3.14159265358979312;
// First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
    vec2 i1  =  (x0.x > x0.y) ? vec2(1.,0.) : vec2(0.,1.) ;

     //  x0 = x0 - 0. + 0. * C
    vec2 x1 = x0 - i1 + 1. * C.xx ;
    vec2 x2 = x0 - 1. + 2. * C.xx ;

// Permutations
    i = mod(i, pParam.x);
    vec3 p = permute( permute( 
             i.y + vec3(0., i1.y, 1. ), pParam.xyz)
             + i.x + vec3(0., i1.x, 1. ), pParam.xyz);

#ifndef USE_CIRCLE
// ( N points uniformly over a line, mapped onto a diamond.)
    vec3 x = fract(p / pParam.w) ;
    vec3 h = 0.5 - abs(x) ;

    vec3 sx = vec3(lessThan(x,D.xxx)) *2. -1.;
    vec3 sh = vec3(lessThan(h,D.xxx));

    vec3 a0 = x + sx*sh;
    vec2 p0 = vec2(a0.x,h.x);
    vec2 p1 = vec2(a0.y,h.y);
    vec2 p2 = vec2(a0.z,h.z);

#ifdef NORMALISE_GRADIENTS
    p0 *= taylorInvSqrt(dot(p0,p0));
    p1 *= taylorInvSqrt(dot(p1,p1));
    p2 *= taylorInvSqrt(dot(p2,p2));
#endif

    vec3 g = 2.0 * vec3( dot(p0, x0), dot(p1, x1), dot(p2, x2) );
#else 
// N points around a unit circle.
    vec3 phi = D.z * mod(p,pParam.w) /pParam.w ;
    vec4 a0 = sin(phi.xxyy+D.xyxy);
    vec2 a1 = sin(phi.zz  +D.xy);
    vec3 g = vec3( dot(a0.xy, x0), dot(a0.zw, x1), dot(a1.xy, x2) );
#endif
// mix
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.);
    m = m*m ;
    return 1.66666* 70.*dot(m*m, g);
}

float simplexNoise3(vec3 v)
{ 
    const vec2  C = vec2(1./6. , 1./3. ) ;
    const vec4  D = vec4(0., 0.5, 1.0, 2.0);

// First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;
    
// Other corners
#ifdef COLLAPSE_SORTNET
    vec3 g = vec3( greaterThan(   x0.xyz, x0.yzx) );
    vec3 l = vec3( lessThanEqual( x0.xyz, x0.yzx) );

    vec3 i1 = g.xyz  * l.zxy;
    vec3 i2 = max( g.xyz, l.zxy);
#else
// Keeping this clean - let the compiler optimize.
    vec3 q1;
    q1.x = max(x0.x, x0.y);
    q1.y = min(x0.x, x0.y);
    q1.z = x0.z;

    vec3 q2;
    q2.x = max(q1.x,q1.z);
    q2.z = min(q1.x,q1.z);
    q2.y = q1.y;

    vec3 q3;
    q3.y = max(q2.y, q2.z);
    q3.z = min(q2.y, q2.z);
    q3.x = q2.x;

    vec3 i1 = vec3(equal(q3.xxx, x0));
    vec3 i2 = i1 + vec3(equal(q3.yyy, x0));
#endif

     //  x0 = x0 - 0. + 0. * C 
    vec3 x1 = x0 - i1 + 1. * C.xxx;
    vec3 x2 = x0 - i2 + 2. * C.xxx;
    vec3 x3 = x0 - 1. + 3. * C.xxx;

// Permutations
    i = mod(i, pParam.x ); 
    vec4 p = permute( permute( permute( 
             i.z + vec4(0., i1.z, i2.z, 1. ), pParam.xyz)
             + i.y + vec4(0., i1.y, i2.y, 1. ), pParam.xyz) 
             + i.x + vec4(0., i1.x, i2.x, 1. ), pParam.xyz);

// Gradients
// ( N*N points uniformly over a square, mapped onto a octohedron.)
    float n_ = 1.0/pParam.w ;
    vec3  ns = n_ * D.wyz - D.xzx ;

    vec4 j = p - pParam.w*pParam.w*floor(p * ns.z *ns.z);  //  mod(p,N*N)

    vec4 x_ = floor(j * ns.z)  ;
    vec4 y_ = floor(j - pParam.w * x_ ) ;    // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1. - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    vec4 s0 = vec4(lessThan(b0,D.xxxx)) *2. -1.;
    vec4 s1 = vec4(lessThan(b1,D.xxxx)) *2. -1.;
    vec4 sh = vec4(lessThan(h, D.xxxx));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

#ifdef NORMALISE_GRADIENTS
    p0 *= taylorInvSqrt(dot(p0,p0));
    p1 *= taylorInvSqrt(dot(p1,p1));
    p2 *= taylorInvSqrt(dot(p2,p2));
    p3 *= taylorInvSqrt(dot(p3,p3));
#endif

// Mix
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.);
    m = m * m;
//used to be 64.
    return 48.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

vec4 grad4(float j, vec4 ip)
{
    const vec4 ones = vec4(1.,1.,1.,-1.);
    vec4 p,s;

    p.xyz = floor( fract (vec3(j) * ip.xyz) *pParam.w) * ip.z -1.0;
    p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
    s = vec4(lessThan(p,vec4(0.)));
    p.xyz = p.xyz + (s.xyz*2.-1.) * s.www; 

    return p;
}

float simplexNoise4(vec4 v)
{
    const vec2  C = vec2( 0.138196601125010504, 
                        0.309016994374947451); 
// First corner
    vec4 i  = floor(v + dot(v, C.yyyy) );
    vec4 x0 = v -   i + dot(i, C.xxxx);

// Other corners

// Force existance of strict total ordering in sort.
    vec4 q0 = floor(x0 * 1024.0) + vec4( 0., 1./4., 2./4. , 3./4.);
    vec4 q1;
    q1.xy = max(q0.xy,q0.zw);   //  x:z  y:w
    q1.zw = min(q0.xy,q0.zw);

    vec4 q2;
    q2.xz = max(q1.xz,q1.yw);   //  x:y  z:w
    q2.yw = min(q1.xz,q1.yw);
    
    vec4 q3;
    q3.y = max(q2.y,q2.z);      //  y:z
    q3.z = min(q2.y,q2.z);
    q3.xw = q2.xw;

    vec4 i1 = vec4(lessThanEqual(q3.xxxx, q0));
    vec4 i2 = vec4(lessThanEqual(q3.yyyy, q0));
    vec4 i3 = vec4(lessThanEqual(q3.zzzz, q0));

     //  x0 = x0 - 0. + 0. * C 
    vec4 x1 = x0 - i1 + 1. * C.xxxx;
    vec4 x2 = x0 - i2 + 2. * C.xxxx;
    vec4 x3 = x0 - i3 + 3. * C.xxxx;
    vec4 x4 = x0 - 1. + 4. * C.xxxx;

// Permutations
    i = mod(i, pParam.x ); 
    float j0 = permute( permute( permute( permute (
                i.w, pParam.xyz) + i.z, pParam.xyz) 
            + i.y, pParam.xyz) + i.x, pParam.xyz);
    vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1. ), pParam.xyz)
             + i.z + vec4(i1.z, i2.z, i3.z, 1. ), pParam.xyz)
             + i.y + vec4(i1.y, i2.y, i3.y, 1. ), pParam.xyz)
             + i.x + vec4(i1.x, i2.x, i3.x, 1. ), pParam.xyz);
// Gradients
// ( N*N*N points uniformly over a cube, 
// mapped onto a 4-octohedron.)
    vec4 ip = pParam ;
    ip.xy *= pParam.w ;
    ip.x  *= pParam.w ;
    ip = vec4(1.,1.,1.,2.) / ip ;

    vec4 p0 = grad4(j0,   ip);
    vec4 p1 = grad4(j1.x, ip);
    vec4 p2 = grad4(j1.y, ip);
    vec4 p3 = grad4(j1.z, ip);
    vec4 p4 = grad4(j1.w, ip);

#ifdef NORMALISE_GRADIENTS
    p0 *= taylorInvSqrt(dot(p0,p0));
    p1 *= taylorInvSqrt(dot(p1,p1));
    p2 *= taylorInvSqrt(dot(p2,p2));
    p3 *= taylorInvSqrt(dot(p3,p3));
    p4 *= taylorInvSqrt(dot(p4,p4));
#endif

// Mix
    vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.);
    vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.);
    m0 = m0 * m0;
    m1 = m1 * m1;
    return 32. * (dot(m0*m0, vec3(dot(p0, x0), dot(p1, x1), dot(p2, x2)))
                 + dot(m1*m1, vec2(dot(p3, x3), dot(p4, x4)))) ;

}

//My util funcs

float dotDist(vec2 x, vec2 y) { //normal vectors, pls
  //return dot(normalize(x), normalize(y));
  return (dot(normalize(x), normalize(y)) + 2) / 4;
}

float dotDist(vec3 x, vec3 y) { //[0,1], [opposite, same]
  //for colors, do color.rgb swizzle
  return (dot(normalize(x), normalize(y)) + 2) / 4;
}

vec2 centro(vec2 p) { //[0,0]x[1,1] -> [-1,-1]x[1,1]
  return (p * 2) - vec2(1, 1);
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * normalize(mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y));
}

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

float BIAS(float x) //0->1, 1->10, so pow(10, x)
{
  return pow(20, x);
}

float plintex(vec3 p)
{
  return (pow(2, simplexNoise3(p) * 2) - 0.25) / 2;//max(simplexNoise3(p), 0); //(simplexNoise3(p) + 1) / 2;
}

vec4 splitSample(sampler2D tex, vec2 i, vec2 j, vec2 k)
{
  float r = texture2D(tex, i).r;
  float g = texture2D(tex, j).g;
  vec2 ba = texture2D(tex, k).ba;
  return vec4(r, g, ba);
}

vec2 centerIt(vec2 p) {
    return (p - vec2(0.5, 0.5)) * 2;
}

vec2 cornerIt(vec2 p) {
    return (p / 2) + vec2(0.5, 0.5);
}

vec2 toPolar(vec2 p) {
    float r = sqrt(p.x*p.x + p.y*p.y);
    float t = atan(p.y, p.x);
    return vec2(r, t);
}

vec2 toCartesian(vec2 p) {
    return vec2(p.x * cos(p.y), p.x * sin(p.y));
}

//sin(x + iy) = sin(x)*cosh(y) + i cos(x)*sinh(y)
//cos(x + iy) = cos(x)*cosh(y) - i sin(x)*sinh(y)
//e^z = e^(x + iy) = e^(x) * e^(iy)= e^x + (cos(y) + i sin(y)) = (e^x + cos(y)) + i sin(y)
//ln(e^iy) = iy, ln(e^(x+iy)) = ln(e^x * e^iy) = ln(e^x) + ln(e^iy) = x + iy
//(x + iy)^2 = (x - y^2) + i(xy) 
//(a + bi) * (c + di) = [(ac - bd) + i(bc + ad)]

vec2 wrap(vec2 p) {
    if (p.x > 1.0) {
        p.x = mod(ceil(p.x), 2.0) == 0.0 ? 1 - mod(p.x, 1.0) : mod(p.x, 1.0);
    }
    if (p.x < 0.0) {
        p.x = mod(ceil(-p.x), 2.0) == 0.0 ? 1 - mod(-p.x, 1.0) : mod(-p.x, 1.0);
    }
    if (p.y > 1.0) {
        p.y = mod(ceil(p.y), 2.0) == 0.0 ? 1 - mod(p.y, 1.0) : mod(p.y, 1.0);
    }
    if (p.y < 0.0) {
        p.y = mod(ceil(-p.y), 2.0) == 0.0 ? 1 - mod(-p.y, 1.0) : mod(-p.y, 1.0);//mod(-p.y, 1.0);
    }
    return p;
}

vec2 wrap2(vec2 p) {
    if (p.x > 1.0) {
        p.x = mod(ceil(p.x), 2.0) == 0.0 ? 1 - mod(p.x, 1.0) : mod(p.x, 1.0);
    }
    if (p.x < 0.0) {
        p.x = mod(ceil(-p.x), 2.0) == 0.0 ? 1 - mod(-p.x, 1.0) : mod(-p.x, 1.0);
    }
    if (p.y > 1.0) {
        p.y = mod(ceil(p.y), 2.0) == 0.0 ? 1 - mod(p.y, 1.0) : mod(p.y, 1.0);
    }
    if (p.y < 0.0) {
        p.y = mod(ceil(-p.y), 2.0) == 0.0 ? 1 - mod(-p.y, 1.0) : mod(-p.y, 1.0);//mod(-p.y, 1.0);
    }
    return (p*2)-vec2(1.0,1.0);
}

vec2 csin(vec2 p) {
    return vec2(sin(p.x)*cosh(p.y), cos(p.x)*sinh(p.y));
}

vec2 ccos(vec2 p) {
    return vec2(cos(p.x)*cosh(p.y), -1*sin(p.x)*sinh(p.y));
}

vec2 csq(vec2 p) {
    return vec2(p.x - p.y*p.y, p.x * p.y);
}

vec2 ce(vec2 p) {
    float e = exp(p.x);
    return vec2(e * cos(p.y), e * sin(p.y));
}

vec2 cmult(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.y * b.x + a.x * b.y);
}

vec2 cconj(vec2 a) {
	return vec2(a.x, -a.y);
}

vec2 cdiv(vec2 a, vec2 b) {
	return vec2((a.x*b.x + a.y*b.y)/(b.x*b.x + b.y*b.y), (a.y*b.x - a.x*b.y)/(b.x*b.x + b.y*b.y));
}

vec2 cpolar(vec2 a) {
	return vec2(sqrt(a.x*a.x + a.y*a.y), atan(a.y, a.x));
}

vec2 clog(vec2 a) {
	vec2 b = cpolar(a);
	b.x = log(b.x);
	return b;
}

vec2 mobius(vec2 z, vec2 z1, vec2 z2, vec2 z3) {
	return cdiv(cmult(z - z1, z2 - z3), cmult(z - z3, z2 - z1));
}

vec2 mobius2(vec2 z, vec2 y1, vec2 y2) {
  return cdiv(z - y1, z - y2);
}

vec2 mobius3(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d) {
  return cdiv(cmult(z, a) + b, cmult(z, c) + d);
}

vec2 mobius4(vec2 z, vec2 _k, vec2 y1, vec2 y2) { //k is (p, a) of k = e^(p + ai)
  vec2 k = ce(_k.xy);
  return mobius3(z, 
    y1 - cmult(k, y2),
    cmult(cmult(k - vec2(1.0, 0.0), y1), y2),
    vec2(1.0, 0.0) - k,
    cmult(k, y1) - y2);
}

vec2 biholomorphic(vec2 z, float phi, vec2 b) {
	return cmult(ce(vec2(1.0, phi)), cdiv(z + b, 1 + cmult(cconj(b), z)));
}

void main()
{
    vec4 color = vec4(0.0);
    vec2 texCoord = vertTexCoord.st;
    vec2 p = texCoord;

    float msc = 10*2;
    float z1x = 1*sin(t*8.19/msc);
    float z1y = 1*cos(t*13.41/msc);
    float z2x = 1*sin(t*2.37/msc);
    float z2y = 1*cos(t*5.58/msc);
    //float z2x = 0.5+0.5*sin(t*8.19/msc);
    //float z2y = 0.5+0.5*cos(t*13.41/msc);
    float z3x = sin(t/16/msc);
    float z3y = cos(t/32/msc);
    float tosc = 0.5;
   
    p = centerIt(p);

    float tz1 = 0.5 + 0.5*sin(t*8);
    float tz = t*8;
    float wid = mix(0, 0.33, tz1);
    p += vec2(wid*cos(tz), wid*sin(tz));
    //p *= 0.45+0.3*sin(-t/2);
    //p *= 0.45+0.25*sin(-t/2);
    p *= mix(0.1, 100.0, 0.5 + 0.5*sin(tz1)*sin(tz1)*sin(tz1));
    //p *= 0.4+0.05*sin(-t*2);
    //0.2 too low
    //0.7 too high
    //[0.3,0.5]

    float t2 = t/16/4;
    float t3 = t/4;

    //p = mobius2(p, vec2(cos(t2*3.0), sin(t2*5.0)), vec2(cos(t2*7.0), sin(t2*11.0)));
    //p = wrap(p);
    float sl = 0.1;
    float kp = 0.5+0.25*cos(_t/8);//mx*5;//0.8*cos(t/7/sl) + 0.1*cos(t*2/sl);
    float ka = 0.0;//sin(_t/8/4/4);//my*5;//0.8*sin(t/3/sl) + 0.1*sin(t*2/sl);
    vec2 k = vec2(kp, ka);
    float mx = 0.6;
    float q = (mx + 1) / 2.0;
    q *= 2;
    p = mobius4(p, k, vec2(-q, 0.0), vec2(q, 0.0));
    //4*vec2(cos(t3*3.0), sin(t3*5.0)), 4*vec2(cos(t3*7.0), sin(t3*11.0))

    //p = biholomorphic(p, -t/11.0, tosc*vec2(z2x, z2y));
    p = wrap(p);

    float z1 = 4.0;//0.75 + 0.25*sin(t/3);
    vec2 mc = p;
    //vec2 q1 = ce(p) * z1;
    //vec2 q1 = ce(vec2(p.x, mod(abs(p.y), PI/(0.5+2.5+2.5*sin(t*1.37))))) * z1;
    //p = q1;

    float ra = sin(t/8);//PI/4 * sin(t/13*8); //rotation angle
    ra *= PI/2;
    ra /= 1;
    ra -= 0.25;
    ra = 16*t;
    //p = cmult(vec2(cos(ra), sin(ra)), p);
    //p = wrap(p);
    //fp = cmult(vec2(cos(ra), sin(ra)), fp);
    //p += vec2(0.5, 0.0);
    //float z2 = 2 + sin(t/3);//1.7 + 0.3*sin(t/2);
    //vec2 q2 = csin(p) * z2;

    float sc = 4;

    //vec2 avg = tosc*vec2(z1x, z1y) + tosc*vec2(z2x, z2y) + tosc*vec2(z3x, z3y);
    //avg /= 3;

    //p += avg;

    //float warpScale = mx;//0.1;
    //float warpGrain = my;//1.0;
    float timeScale = 4.0;
    p += warpScale*vec2(simplexNoise3(vec3(p.x/warpGrain, p.y/warpGrain, t/timeScale)), simplexNoise3(vec3(p.x/warpGrain, p.y/warpGrain, 100+t/timeScale)));
    p = wrap(p);
    //p = cmult(vec2(cos(ra), sin(ra)), p);
    //p = wrap(p);

    vec2 fp = p;
    //fp = wrap(fp);
    //fp = mobius(fp, tosc*vec2(z1x, z1y), tosc*vec2(z2x, z2y), tosc*vec2(z3x, z3y));
    //fp = mobius(fp, vec2(Z1x, Z1y), vec2(Z2x, Z2y), vec2(Z3x, Z3y));//wrap(p);
    //fp = biholomorphic(fp, t/17.0, centerIt(texCoord));
    
    //fp = biholomorphic(fp, t/17.0, tosc*vec2(z1x, z1y));
    
    //fp = mix(csin(fp), ccos(fp), (1+sin(t/1.43))/2);
    //fp = cdiv(csin(fp), ccos(fp));

    fp = wrap(fp);

    //p = mix(q1, q2, 0.5 + 0.5*sin(t/7));// + vec2(simplexNoise3(vec3(q1.xy*sc, t/5)), simplexNoise3(vec3(q2.xy*sc, t/5)))/32;
    //p = mix(p, ccos(p), 0.5 + 0.5*sin(t/3));

    //vec2 u = toPolar(p);

    //p = mix(p, u, 0.5 + 0.5*cos(t/5));
    //p.x = mod(p.x, 1.0);
    //p.y = mod(p.y, PI*2/3) -PI/2;
    //p = toCartesian(p);
    //p = cornerIt(p); //+ vec2(cos(t/2), sin(t/2))/2;//vec2(-0.75 + 0.1*sin(t), 0);
    
    //p = cornerIt(p);

    //fp = clog(p);

    //p = wrap(p);

    //Set two fixed points: texCoord, and pos(texCoord)
    //k = (a+d)+sqrt((a-d)*(a-d) + 4*b*c)/
    //    (a+d)-sqrt((a-d)*(a-d) + 4*b*c)
    //Let pos(texCoord) = 
    //Let k(texCoord) = 

    
    /*float k = (a+d)+sqrt((a-d)*(a-d) + 4*b*c)/
              (a+d)-sqrt((a-d)*(a-d) + 4*b*c);*/
    //For this I wanted to be able to define a mobius transformation
    //with a certain k, to warp different at each point

    //vec4 c1 = texture2D(prevFrame, p);
    vec4 c2 = texture2D(prevFrame, fp);
    vec4 c = c2;
    //vec4 c = mix(c1, c2, pow(sin(t/2), 6));
    //vec4 c = mix(mix(min(c1, c2), max(c1, c2), 0.5+0.5*sin(t*8)), mix(c1, c2, (sin(t)*sin(t))), 0.5+0.5*cos(t*4));//mix(c1, c2, 0.5);
    vec3 hsv = rgb2hsv(c.rgb);
    float satBoost = 0.025;
    float brightBoost = 0.05;
    vec4 col = vec4(hsv2rgb(hsv + vec3(0.0, satBoost, brightBoost)), c.a);

    color.r = col.r;
    color.g = col.g;
    color.b = col.b;
    color.a = col.a;

    gl_FragColor = color;
}

/*Gonna do this shit manually
for (int i = 0; i < 9; i++)
    {
        color += texture2D( texture, current ) * conMatrix[i]; 

        current.x += texOffset.x;
        if (i == 2 || i == 5) {
            current.x = start.x;
            current.y += texOffset.y; 
        }
    }*/

/*conMatrix[0] = 1.0; //top-left
  conMatrix[1] = 1.0; //top-middle
  conMatrix[2] = -1.0; //top-right
  
  conMatrix[3] = 1.0; //middle-left
  conMatrix[4] = 1.0; //center
  conMatrix[5] = 1.0; //middle-right
  
  conMatrix[6] = 1.0; //bottom-left
  conMatrix[7] = 1.0; //bottom-middle
  conMatrix[8] = 1.0; //bottom-right*/