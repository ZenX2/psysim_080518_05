interface VectorPath {
  boolean close = false;
  PVector path(float t);
  void onCreate();
  void garnish(PVector p, PGraphics buffer, float a, int i, float j);
}

class PatternLine implements VectorPath {
  float w=10;
  color lineColor;
  int resolution = 200;
  int garnishCount = int(resolution*0.5);
  float scale = 100;
  float phase = 0;
  float velocity = 0;

  public PatternLine(float _w, float _scale, color _lineColor) {
    w = _w;
    lineColor = _lineColor;
    scale = _scale;
    onCreate();
  }

  PVector path(float t) {
    return new PVector(t, 0);
  }

  void onCreate() {
  }

  void garnish(PVector p, PGraphics buffer, float a, int i, float j) {
    buffer.fill(0, 255, 0, 20);
    buffer.noStroke();
    buffer.pushMatrix();
    buffer.translate(p.x, p.y);
    //buffer.rotate(a);
    buffer.rotate(a + (i % 2 == 0 ? PI/2 : -PI/2));
    buffer.translate(-5.0, 0.0);
    buffer.scale(0.65, 0.65); //height, width
    equiTriangle(w*taperFunc(j/garnishCount), buffer);
    buffer.popMatrix();
  }
  
  private float taperFunc(float x) { //[0,1]
    float t = x;
    t -= 0.5;
    t *= 2.0;
    t *= t;
    //t /= 1.5;
    t = 1-t;
    return t;
  }

  void draw(PGraphics buffer) {
    buffer.stroke(lineColor);
    buffer.strokeWeight(w);
    for (int i = 1; i < resolution; i++) {
      float t = float(i)/resolution;
      float s = float(i-1)/resolution;
      PVector a = path(t).mult(scale);
      PVector b = path(s).mult(scale);
      buffer.strokeWeight(w*taperFunc(float(i)/resolution));
      buffer.line(b.x, b.y, a.x, a.y);
    }

    if (close) {
      float t = 0.0;
      float s = float(resolution-1)/resolution;
      PVector a = path(t).mult(scale);
      PVector b = path(s).mult(scale);
      buffer.line(b.x, b.y, a.x, a.y);
    }
    
    float velocityTarget = 0.005;
    float velBump = 0.075;
    float velDamp = 16;
    
    if (bassBeat()) velocity = velBump;
    velocity += (velocityTarget - velocity)/velDamp;
    phase += velocity;
    float timeScale = 4;
    for (int i = 0; i < garnishCount; i++) {
      float q = ((float(i)+phase*timeScale)%garnishCount)/garnishCount;
      float v = ((float(i-1)+phase*timeScale)%garnishCount)/garnishCount;
      PVector c = path(q).mult(scale);
      PVector d = path(v).mult(scale);
      PVector e = PVector.sub(c, d);
      garnish(c, buffer, atan2(e.y, e.x), i, ((float(i)+phase*timeScale)%garnishCount));
    }
  }
}
