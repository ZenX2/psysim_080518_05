class Bust {
 PShape bust;
 PShader defaultTextureShader;
 
 Bust() {
  //bust = loadShape("bust/ROMAN BUST LOW POLY.obj"); 
  //bust = createShape(SPHERE, 100);
  defaultTextureShader = loadShader("defaultTexture.glsl");
 }
 
 PVector bustPos() {
   return new PVector(width/2, height, 500);
 // return new PVector(width/2, height/2, 300);
  //return new PVector(1000 + -500*cos(-seconds()*TWO_PI/8), 900 + (50 + ((4*seconds() % 4 < 1) ? (200) : (0)))*sin(seconds()*16), -1000 + 500*sin(-seconds()*TWO_PI/8));
}

 void draw(PImage tex) {
  pushMatrix();
  PVector bp = bustPos();
  //translate(bp.x, bp.y, bp.z);
  //scale(100);
  rotateX(PI);
  rotateY(seconds());
  rotateZ(PI/6*sin(seconds()*2));
  bust.setTexture(tex);
  scale(2);
  colorMode(HSB, 255);
  bust.setTint(color((seconds()*1*255)%255, 100, 255, 255));
  colorMode(RGB, 255);
  bust.setStroke(color(255, 0));
  shader(defaultTextureShader);
  shape(bust);
  tint(255, 255);
  popMatrix();
}
}
