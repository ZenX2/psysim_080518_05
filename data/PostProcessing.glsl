#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

//uniform sampler2D texture;
uniform int       filterNumber;
uniform vec2      tcOffset[25]; // Texture coordinate offsets

//in vec2 vTex;

//out vec4 gl_FragColor;

uniform sampler2D texture;
uniform vec2 texOffset;
varying vec4 vertColor;
varying vec4 vertTexCoord;
uniform float t;
uniform float strength;

void main(void)
{
  vec2 vTex = vertTexCoord.st;
  // Standard
  if (filterNumber == 0)
  {
    gl_FragColor = texture2D(texture, vTex);
  }

  // Greyscale
  if (filterNumber == 1)
  {
    // Convert to greyscale using NTSC weightings
    float grey = dot(texture2D(texture, vTex).rgb, vec3(0.299, 0.587, 0.114));

    gl_FragColor = vec4(grey, grey, grey, 1.0);
  }

  // Sepia tone
  if (filterNumber == 2)
  {
    // Convert to greyscale using NTSC weightings
    float grey = dot(texture2D(texture, vTex).rgb, vec3(0.299, 0.587, 0.114));

    // Play with these rgb weightings to get different tones.
    // (As long as all rgb weightings add up to 1.0 you won't lighten or darken the image)
    gl_FragColor = vec4(grey * vec3(1.2, 1.0, 0.8), 1.0);
  }

  // Negative
  if (filterNumber == 3)
  {
    vec4 texMapColour = texture2D(texture, vTex);

    gl_FragColor = vec4(1.0 - texMapColour.rgb, 1.0);
  }

  // Blur (gaussian)
  if (filterNumber == 4)
  {
    vec4 _sample[25];

    for (int i = 0; i < 25; i++)
    {
      // _sample a grid around and including our texel
      _sample[i] = texture2D(texture, vTex + tcOffset[i]/strength);
    }

    // Gaussian weighting:
    // 1  4  7  4 1
    // 4 16 26 16 4
    // 7 26 41 26 7 / 273 (i.e. divide by total of weightings)
    // 4 16 26 16 4
    // 1  4  7  4 1

        gl_FragColor = (
                     (1.0  * (_sample[0] + _sample[4]  + _sample[20] + _sample[24])) +
                     (4.0  * (_sample[1] + _sample[3]  + _sample[5]  + _sample[9] + _sample[15] + _sample[19] + _sample[21] + _sample[23])) +
                     (7.0  * (_sample[2] + _sample[10] + _sample[14] + _sample[22])) +
                     (16.0 * (_sample[6] + _sample[8]  + _sample[16] + _sample[18])) +
                     (26.0 * (_sample[7] + _sample[11] + _sample[13] + _sample[17])) +
                     (41.0 * _sample[12])
                     ) / 273.0;

  }

  // Blur (mean filter)
  if (filterNumber == 5)
  {
    gl_FragColor = vec4(0.0);

    for (int i = 0; i < 25; i++)
    {
      // _sample a grid around and including our texel
      gl_FragColor += texture2D(texture, vTex + tcOffset[i]/strength);
    }

    // Divide by the number of _samples to get our mean
    gl_FragColor /= 25;
  }

  // Sharpen
  if (filterNumber == 6)
  {
    vec4 _sample[25];

    for (int i = 0; i < 25; i++)
    {
      // _sample a grid around and including our texel
      _sample[i] = texture2D(texture, vTex + tcOffset[i]/strength);
    }

    // Sharpen weighting:
    // -1 -1 -1 -1 -1
    // -1 -1 -1 -1 -1
    // -1 -1 25 -1 -1
    // -1 -1 -1 -1 -1
    // -1 -1 -1 -1 -1

        gl_FragColor = 25.0 * _sample[12];

    for (int i = 0; i < 25; i++)
    {
      if (i != 12)
        gl_FragColor -= _sample[i];
    }
  }

  // Dilate
  if (filterNumber == 7)
  {
    vec4 _sample[25];
    vec4 maxValue = vec4(0.0);

    for (int i = 0; i < 25; i++)
    {
      // _sample a grid around and including our texel
      _sample[i] = texture2D(texture, vTex + tcOffset[i]/strength);

      // Keep the maximum value   
      maxValue = max(_sample[i], maxValue);
    }

    gl_FragColor = maxValue;
  }

  // Erode
  if (filterNumber == 8)
  {
    vec4 _sample[25];
    vec4 minValue = vec4(1.0);

    for (int i = 0; i < 25; i++)
    {
      // _sample a grid around and including our texel
      _sample[i] = texture2D(texture, vTex + tcOffset[i]/strength);

      // Keep the minimum value   
      minValue = min(_sample[i], minValue);
    }

    gl_FragColor = minValue;
  }

  // Laplacian Edge Detection (very, very similar to sharpen filter - check it out!)
  if (filterNumber == 9)
  {
    vec4 _sample[25];

    for (int i = 0; i < 25; i++)
    {
      // _sample a grid around and including our texel
      _sample[i] = texture2D(texture, vTex + tcOffset[i]/strength);
    }

    // Laplacian weighting:
    // -1 -1 -1 -1 -1
    // -1 -1 -1 -1 -1
    // -1 -1 24 -1 -1
    // -1 -1 -1 -1 -1
    // -1 -1 -1 -1 -1

        gl_FragColor = 24.0 * _sample[12];

    for (int i = 0; i < 25; i++)
    {
      if (i != 12)
        gl_FragColor -= _sample[i];
    }
  }
}