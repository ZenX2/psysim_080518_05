import java.util.function.*;

abstract class Element {
  color col = color(0);
  abstract void draw();
  abstract void draw(PGraphics buffer);
  abstract void update(PVector p);
}

class CircleElement extends Element {
  color col = color(0);
  float radius = 10;
  float scale = 10;
  
  float radiusFunc(PVector p) {
   return logistic(p.x + 1*sin(seconds()), 4.0); 
  }
  
  void update(PVector p) {
   radius = radiusFunc(p) * scale; 
  }
  
  void draw() {
    fill(col);
    stroke(col);
    ellipse(0, 0, radius, radius);
  }
  void draw(PGraphics buffer) {
    buffer.fill(col);
    buffer.stroke(col);
    buffer.ellipse(0, 0, radius, radius);
  }
}

class SquareElement extends Element {
  color col = color(0);
  float edge = 10;
  float corner = 10;
  float scale = 10;
  float EDGE = 0;
  float CORNER = 0;
  
  float edgeFunc(PVector p) {
    PVector adjp = PVector.add(p, new PVector(-0.5, -0.5));
    float d = adjp.mag();
    //return max(0.0, 1.0 - (d*2));//sin(d*2 - seconds());
    //return 1.2*logistic(p.x - 0.25 + 0.5*sin(seconds()/2), 4.0);
    return EDGE;//log(1+2*EDGE) * sin(d*(8+4) + 2*seconds());
  }
  
  float cornerFunc(PVector p) {
    PVector adjp = PVector.add(p, new PVector(-0.5, -0.5));
    float d = adjp.mag();
    return 10 + 10*sin(d*8 - 3*seconds()); //max(0, 10 - CORNER*25);
   //return 10 + 10*sin(p.y*4 + seconds()*3);
  }
  
  void update(PVector p) {
   edge = edgeFunc(p) * scale;
   corner = cornerFunc(p);
  }
  
  void draw() {
    fill(col, 150);
    stroke(beat.isKick() || beat.isSnare() ? color(random(255), 255, 255) : 0);
    rect(-edge/2, -edge/2, edge, edge, corner, corner, corner, corner);
  }
  void draw(PGraphics buffer) {
    buffer.fill(col, 150);
    buffer.stroke(beat.isKick() || beat.isSnare() ? color(random(255), 255, 255) : 0);
    buffer.rect(-edge/2, -edge/2, edge, edge, corner, corner, corner, corner);
  }
}

//HEXAGONS
PShape hexagonShape;
PShape getHexagonShape() {
  if (hexagonShape != null) return hexagonShape;
  hexagonShape = createShape();
  hexagonShape.beginShape();
  //hexagonShape.noStroke();
  for (int i = 0; i < 6; i++) {
   float p = i/6.0*TWO_PI;
   hexagonShape.vertex(cos(p), sin(p)); 
  }
  hexagonShape.endShape(CLOSE);
  return hexagonShape;
}

class HexagonElement extends Element {
  color col = color(0);
  float radius = 10;
  float scale = 30.0;
  float angle = 0;
  float SIZE = 0;
  float SC = 1.0;
  
  float radiusFunc(PVector p) {
    PVector adjp = PVector.add(p, new PVector(-0.45, -0.45));
    float d = adjp.mag();
    //return max(0.0, 1.0 - (d*2));//sin(d*2 - seconds());
    //return 1.2*logistic(p.x - 0.25 + 0.5*sin(seconds()/2), 4.0);
    return sin(d*(8+4) + -2*_seconds()) * (1+cos(seconds()/2))/2;
   //return logistic(p.x + 1*sin(seconds()), 4.0); 
  }
  
  void update(PVector p) {
   radius = radiusFunc(p) * scale; 
  }
  
  void draw() {
    PShape hex = getHexagonShape();
    hex.setFill(col);
    //hex.setStroke(beat.isKick() || beat.isSnare() ? color(random(255), 255, 255) : 0);
    pushMatrix();
    rotate(angle);
    scale(radius);
    shape(hex);
    popMatrix();
  }
  void draw(PGraphics buffer) {
    PShape hex = getHexagonShape();
    hex.setFill(col);
    hex.setStrokeWeight(0.1);
    hex.setStroke(color(255, 255, 255, 150));
    //hex.setStroke(color(255, 255, 255, 255));
    //hex.setStroke(beat.isKick() || beat.isSnare() ? color(255, 255, 255) : 0);
    buffer.pushMatrix();
    buffer.rotate(angle);
    buffer.scale(radius);
    //buffer.scale(1.0);
    buffer.shape(hex);
    //buffer.image(yinyang, 0, 0);
    //buffer.tint(255, 255);
    //buffer.image(eyeBuffer, -eyeBuffer.width/2, -eyeBuffer.height/2);
    buffer.popMatrix();
  }
}

class EyeElement extends Element {
  color col = color(0);
  float radius = 10;
  float scale = 0.3;
  float angle = 0;
  float SIZE = 0;
  float SC = 1.0;
  
  float radiusFunc(PVector p) {
    PVector adjp = PVector.add(p, new PVector(-0.45, -0.45));
    float d = adjp.mag();
    //return max(0.0, 1.0 - (d*2));//sin(d*2 - seconds());
    //return 1.2*logistic(p.x - 0.25 + 0.5*sin(seconds()/2), 4.0);
    return sin(d*(8+4) + _seconds()/2) * (1+cos(seconds()/2))/2;
   //return logistic(p.x + 1*sin(seconds()), 4.0); 
  }
  
  void update(PVector p) {
   radius = radiusFunc(p) * scale; 
  }
  
  void draw() {
    PShape hex = getHexagonShape();
    hex.setFill(col);
    //hex.setStroke(beat.isKick() || beat.isSnare() ? color(random(255), 255, 255) : 0);
    pushMatrix();
    rotate(angle);
    scale(radius);
    shape(hex);
    popMatrix();
  }
  void draw(PGraphics buffer) {
    //PShape hex = getHexagonShape();
    //hex.setFill(col);
    //hex.setStrokeWeight(0.1);
    //hex.setStroke(color(255, 255, 255, 150));
    //hex.setStroke(color(255, 255, 255, 255));
    //hex.setStroke(beat.isKick() || beat.isSnare() ? color(255, 255, 255) : 0);
    buffer.pushMatrix();
    buffer.rotate(angle);
    buffer.scale(radius);
    //buffer.shape(hex);
    buffer.tint(255, 255);
    buffer.image(eyeBuffer, -eyeBuffer.width/2, -eyeBuffer.height/2);
    buffer.popMatrix();
  }
}
