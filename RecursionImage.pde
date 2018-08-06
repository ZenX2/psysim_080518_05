class RecursionImage {
  PImage img;
  float offsetInitial = 10.0;
  float offsetMult = 1.1;
  float rotationInitial = PI/32;
  float rotationMult = 1.0;
  float scaleInitial = 1.0;
  float scaleMult = 0.99;
  int levels = 10;
  RecursionImage(PImage i) {
    img = i;
  }
  float offset(int i) {
    return offsetInitial * pow(offsetMult, i);
  }
  float rotation(int i) {
    return rotationInitial * pow(rotationMult, i);
  }
  float scaling(int i) {
    return scaleInitial * pow(scaleMult, i);
  }
  
  void update() {
    float timing = 0.05;
    offsetInitial = 100*cos(_seconds()*timing*2);
    rotationInitial = (PI/16)*sin(_seconds()*timing);
  }
  
  void draw(float f) {
    update();
    pushMatrix();
    rotate(_seconds()/8 + f);
    scale(0.2);
    for (int i = 0; i < levels; i++) {
      rotate(rotation(i));
      translate(offset(i), 0);
      scale(scaling(i));
    }
    for (int i = levels - 1; i >= 0; i--) {
      image(img, -img.width/2, -img.height/2);
      scale(1.0/scaling(i));
      translate(-offset(i), 0);
      rotate(-rotation(i));
    }
    popMatrix();
  }
  void draw(float f, PGraphics buffer) {
    update();
    buffer.pushMatrix();
    buffer.rotate(seconds() + f);
    buffer.scale(1.0);
    for (int i = 0; i < levels; i++) {
      buffer.rotate(rotation(i));
      buffer.translate(offset(i), 0);
      buffer.scale(scaling(i));
    }
    for (int i = levels - 1; i >= 0; i--) {
      float x = 1.0 - float(i)/(levels-1);
      float y = float(i)/levels;
      colorMode(HSB, 255);
      float cutoff = 0.5;
      if (x > cutoff)
        x = 1.0;
      else
        x = x/cutoff;
      x = log(x+1)/log(2);
      float a = 1;
      float b = a-1;
      buffer.tint(color((seconds()*2*255 + y*255*8)%255, 10, 255), min(a*255*x - b*255, 255));
      colorMode(RGB, 255);
      buffer.image(img, -img.width/2, -img.height/2);
      buffer.scale(1.0/scaling(i));
      buffer.translate(-offset(i), 0);
      buffer.rotate(-rotation(i));
    }
    buffer.popMatrix();
  }
}
