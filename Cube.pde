class Cube {
  PShader cube;
  PGraphics buffer;

  Cube() {
    this.buffer = createGraphics(height/4, height/4, P2D);
    cube = loadShader("Cube.glsl");
  }

  void render() {
    this.buffer.beginDraw();
    this.buffer.background(255);
    cube.set("t", seconds()*16);
    cube.set("resx", float(this.buffer.width));
    cube.set("resy", float(this.buffer.height));
    this.buffer.filter(cube);
    this.buffer.endDraw();
  }
  
  void draw() {
    //render();
    pushMatrix();
    scale(2);
    image(this.buffer, -this.buffer.width/2, -this.buffer.height/2);
    popMatrix();
  }
  
  void draw(PGraphics destination) {
    //render();
    destination.pushMatrix();
    destination.scale(2);
    colorMode(HSB, 255);
    destination.tint(color((seconds()*255)%255, 75, 255), 255);
    colorMode(RGB, 255);
    destination.image(this.buffer, -this.buffer.width/2, -this.buffer.height/2);//-buffer.width/2, -buffer.height/2
    destination.popMatrix();
  }
}
