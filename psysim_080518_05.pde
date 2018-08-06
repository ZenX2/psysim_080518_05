import controlP5.*;

import processing.video.*;

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
import java.io.File;
import java.io.FileFilter;
import java.awt.event.KeyEvent;

ControlP5 UI;

PGraphics buffer;
PGraphics buffer2;
PShader postProcessing;
PShader hueShift;
PatternLine pl;
Palette pal;

int numRecur = 0;
RecursionImage[] recur;
PImage gradient;

PImage backgroundImg;
Movie backgroundMov;
PImage yinyang;
PImage logo;

PImage menuIcon;
float menuIconVal = 0;
float menuIconTarget = 0;
float menuIconDamp = 0.1;
int lastMouseX = 0;

DiamondGrid squareGrid;
Field field;
DiamondGrid squareGrid2;
Field field2;
float gridScale = 20*1.2;

Minim minim;
AudioPlayer song;
BeatDetect beat;
//BeatListener bl;
AudioInput in;

float rtarget = 0;
float rvar = 0;

PVector Z1;
PVector Z2;
PVector Z3;

int dragging = 0;

int TIME = 0;
int RAWTIME = 0;
int lastTime = 0;
float timeMult = 1.0;
float timeMultTarget = 0.1;
float timeMultDamp = 0.4;

boolean exclusionSwitch = false;

PGraphics eyeBuffer;

SymbolGenerator symbolGenerator;
Bust bust;
Cube cube;

boolean paused = false;

boolean splashScreenOn = true;
boolean splashScreenFirstDraw = true;
PImage splashScreenImg;
int splashScreenTimerStart;
int splashScreenTimer;

void setup() {
  //size(1280, 720, P2D); 
  //size(960, 540, P2D); 
  fullScreen(P2D);
  buffer = createGraphics(width, height, P2D);
  buffer2 = createGraphics(width, height, P2D);
  hueShift = loadShader("HueShift.glsl");

  splashScreenImg = loadImage("splashscreen.png");

  UI = new ControlP5(this);

  logo = loadImage("geometry_sim.png");
  menuIcon = loadImage("menu.png");

  cube = new Cube();
  bust = new Bust();
  //PVector p = bust.bustPos();
  camera(width/2, height/2, -100, width/2, height/2, 0.0, 
    0.0, 1.0, 0.0);

  //yinyang = loadImage("images/yingyany.gif");

  gradient = loadImage("fadeCircle.png");
  backgroundImg = loadImage("background2.jpg");
  //backgroundMov = new Movie(this, "MoreTor.mp4");
  //backgroundMov.loop();

  eyeBuffer = createGraphics(400, 400, P2D);
  renderSymbol();

  File[] imageFiles = new File(sketchPath()+"/data/images").listFiles(new FileFilter() {
    public boolean accept(File pathname) {
      String name = pathname.getName();
      return (name.length() > 4 && (name.substring(name.length() - 4).equals(".png") || name.substring(name.length() - 4).equals(".gif")));
    }
  }
  );
  numRecur = imageFiles.length;
  recur = new RecursionImage[numRecur];
  for (int i = 0; i < numRecur; i++) {
    //println(imageFiles[i].getName());
    recur[i] = new RecursionImage(loadImage("images/" + imageFiles[i].getName()));
  }

  //FIELD SETUP
  squareGrid = new DiamondGrid(9*1, 9*1);
  squareGrid.scaling = new PVector(width*1.5, height*5.0);
  field = new Field(squareGrid);
  squareGrid2 = new DiamondGrid(9*3, 9*3);
  squareGrid2.scaling = new PVector(width*0.5, height*0.75);
  field2 = new Field(squareGrid2);

  colorMode(HSB, 255);
  for (int i = 0; i < squareGrid.elementCount; i++) {
    EyeElement ce = new EyeElement();
    ce.col = color((float(i)/squareGrid.elementCount)*255, 200, 200, 100);
    //ce.scale = gridScale;
    field.addElement(ce);
  }

  for (int i = 0; i < squareGrid2.elementCount; i++) {
    HexagonElement he = new HexagonElement();
    he.col = color((float(i)/squareGrid2.elementCount)*255, 200, 200, 100);
    //ce.scale = gridScale;
    field2.addElement(he);
  }
  colorMode(RGB, 255);

  symbolGenerator = new SymbolGenerator();
  symbolGenerator.genRoadLayers(50);

  /////SHADER

  Z1 = new PVector(random(10)/10.0, random(10)/10.0);
  Z2 = new PVector(random(10)/10.0, random(10)/10.0);
  Z3 = new PVector(random(10)/10.0, random(10)/10.0);

  //SOUND STUFF
  minim = new Minim(this);
  in = minim.getLineIn();
  //song = minim.loadFile("LORD OF 420.mp3", 1024);
  //song.play();

  beat = new BeatDetect(in.bufferSize(), in.sampleRate());
  beat.setSensitivity(100);  
  //beat.detectMode(BeatDetect.FREQ_ENERGY);
  //bl = new BeatListener(beat, in.mix);  

  postProcessing = loadShader("PostProcessing.glsl");
  float tcOffset[] = new float[50];
  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 5; x++) {
      tcOffset[2*(x + 5*y)] = float(x-2);
      tcOffset[2*(x + 5*y) + 1] = float(y-2);
    }
  }
  postProcessing.set("tcOffset", tcOffset, 2);
  postProcessing.set("strength", 500.0);

  pal = new Palette();
  /*pal.addColor(color(201, 255, 229));
   pal.addColor(color(220, 20, 60));
   pal.addColor(color(164, 198, 57));
   pal.addColor(color(59, 68, 75));
   pal.addColor(color(165, 42, 42));
   pal.addColor(color(99, 119, 91));
   pal.addColor(color(230, 230, 250));*/
  //pal.addColor(color(55, 82, 149)); //christmas blue
  //pal.addColor(color(10, 20, 0));
  //pal.addColor(color(242, 240, 230)); //alabaster
  //pal.addColor(color(255, 188, 217)); //cotton candy
  //pal.addColor(color(255, 79, 0)); //international orange
  //pal.addColor(color(47, 132, 124)); //celadon green

  colorMode(HSB, 255);
  for (int i = 0; i < 4; i++) {
    //pal.addColor(color((float(i)/8+0.5*noise(i-50))*255, 150+50*noise(i), 150+50*noise(i+50)));
    //pal.addColor(color(0, 0, 255));
  }
  colorMode(RGB, 255);

  //pal.addColor(color(136, 6, 206)); //french violet

  //pal.addColor(color(242, 240, 230)); //alabaster
  float upshift = 50;
  pal.addColor(color(255, 255, 255));
  pal.addColor(color(47+upshift*3, 132+upshift*2, 124+upshift*2)); //celadon green
  pal.addColor(color(255, 255, 255));
  pal.addColor(color(136+upshift*2, 6+upshift*4, 206+upshift));
  pal.addColor(color(200, 200, 200));
  pal.addColor(color(55+upshift*3, 82+upshift*3, 149+upshift*2));
  pal.addColor(color(255, 255, 255));
  pal.addColor(color(255, 188+upshift, 217+upshift/2));

  //pal.addColor(color(0, 20, 10));
  //pal.addColor(color(255, 246, 0)); //cadmium yellow

  pl = new PatternLine(10, 400, color(0, 0, 255, 10)) {
    boolean close = false;
    PVector points[];

    public void onCreate() {
      /*points = new PVector[resolution];
       points[0] = new PVector(0, 0);
       for (int i = 1; i < resolution; i++) {
       float x = points[i-1].x;
       float y = points[i-1].y;
       float sc = 1.0/4;
       float dm = 1;
       points[i] = PVector.add(points[i-1], new PVector(noise(x*sc,y*sc, seconds())/dm, noise(x*sc,y*sc, seconds())/dm));
       }*/
    }

    /*public PVector path(float t) {
     float r = (1.75 + rvar);// + sin(seconds()/10)/2); //0.5*sin(t*TWO_PI*16)
     int i = max(0, floor(t*resolution));
     float st = t * pow(2, 5*sin(seconds()/11));
     int sp;
     if (t < 0.5) {
     sp = int(map( max(t, 0), 0, 0.5, 0, song.bufferSize()));
     r += 0.5*song.left.get(sp) + 0.5*song.left.get(max(0, sp-1));
     } else {
     sp = int(map( min(t, 1), 1.0, 0, 0, song.bufferSize()));
     r += 0.5*song.right.get(sp) + 0.5*song.right.get(max(0, sp-1));
     }
     
     //   line( x1, 50 + song.left.get(i)*50, x2, 50 + song.left.get(i+1)*50 );
     //  line( x1, 150 + song.right.get(i)*50, x2, 150 + song.right.get(i+1)*50 );
     //}
     return new PVector(r*cos(t*TWO_PI)/2, r*sin(t*TWO_PI)/2);
     //return new PVector(cos(t*TWO_PI) + noise(st, seconds())-0.5, sin(t*TWO_PI) + noise(st, seconds()+100)-0.5);//points[i];
     //return new PVector(r*cos(t*TWO_PI*(5 + 3*sin(seconds()/5))), 1.5*r*sin(t*TWO_PI*(5 + 3*sin(seconds()/9))));
     //return new PVector(cos(seconds()) + r*cos(t*TWO_PI*(2.5 + 0.5*sin(seconds()/5))), sin(seconds()) + r*sin(t*TWO_PI*(2.5 + 0.5*sin(seconds()/9))));
     }*/

    public PVector path(float t) {
      float s = sin(seconds()/64);
      float bias = 0.5 + 0.5*(s*s*s*s*s*s*s*s*s);
      return spiral(t).mult(bias).add(squareSpiral(t).mult(1.0-bias));
    }

    public PVector spiral(float t) {
      float r = 4 * t;
      //float r = (0.0 + (2+rvar/2) * t);// + sin(seconds()/10)/2); //0.5*sin(t*TWO_PI*16)
      int sp = int(map( max(t, 0), 0, 1.0, 0, in.bufferSize()));
      float musicDamp = 8;
      float loops = 1.25 + 2 + 2*cos(seconds()/4);
      //r += (0.5*song.mix.get(sp) + 0.5*song.mix.get(max(0, sp-1)))/musicDamp;
      return new PVector(r*cos(t*TWO_PI*loops)/2, r*sin(t*TWO_PI*loops)/2);
    }
    public PVector squareSpiral(float t) {
      int numTurns = floor(12+6*sin(seconds()/24));
      float bt = t * numTurns;
      float st = bt % 1.0;
      float pt = (2*st) % 1.0;
      float turn = floor(bt - st);
      float percent = (turn+1)/numTurns; //percent of total width
      float voffset = (numTurns - turn) / 2; //naming based on first line
      float hoff = (0.5 + turn/2)/numTurns;
      float boff = (0.0 + turn/2)/numTurns;
      float dinkle = pt*((turn+1)/numTurns);
      float binkle = pt*((turn)/numTurns);
      //Even lines center on (0.5, 0.5)
      //Odd lines center on the start of the first line
      PVector position = new PVector(0.5, 0.5);
      if (turn % 2 == 0) {
        if (st < 0.5) {
          position.x += hoff;
          position.y += boff;

          position.y -= binkle;
        } else {
          position.x += hoff;
          position.y -= hoff;

          position.x -= dinkle;
        }
      } else {
        if (st < 0.5) {
          position.x -= hoff;
          position.y -= boff;

          position.y += binkle;
        } else {
          position.x -= hoff;
          position.y += hoff;

          position.x += dinkle;
        }
      }
      return position;
    }
  };
}

void keyPressed() {
  PVector m = new PVector(map(mouseX, 0, width, 0, 1), map(mouseY, 0, height, 0, 1));
  if (key == 's') {
    saveFrame("screenshot-######.png");
  }
  if (key == ' ') {
    paused = !paused;
    //println("YUH");
  }
  /*if (key == 'z') {
   Z1.x = m.x;
   Z1.y = m.y;
   }
   if (key == 'x') {
   Z2.x = m.x;
   Z2.y = m.y;
   }
   if (key == 'c') {
   Z3.x = m.x;
   Z3.y = m.y;
   }*/
}

void mousePressed() {
  PVector m = new PVector(map(mouseX, 0, width, -1, 1), map(mouseY, 0, height, -1, 1));
  if (m.dist(Z1) < 0.1) {
    dragging = 1;
  }
  if (m.dist(Z2) < 0.1) {
    dragging = 2;
  }
  if (m.dist(Z3) < 0.1) {
    dragging = 3;
  }
}

void mouseReleased() {
  dragging = 0;
}

void updateDragging() {
  if (dragging == 0) return;
  PVector m = new PVector(map(mouseX, 0, width, -1, 1), map(mouseY, 0, height, -1, 1));
  if (dragging == 1) {
    Z1.x = m.x;
    Z1.y = m.y;
  }
  if (dragging == 2) {
    Z2.x = m.x;
    Z2.y = m.y;
  }
  if (dragging == 3) {
    Z3.x = m.x;
    Z3.y = m.y;
  }
}

void drawMobiusPoints() {
  fill(255);
  stroke(255, 0, 0);
  strokeWeight(3);
  ellipse((Z1.x+1)/2*width, (Z1.y+1)/2*height, 10, 10);
  ellipse((Z2.x+1)/2*width, (Z2.y+1)/2*height, 10, 10);
  ellipse((Z3.x+1)/2*width, (Z3.y+1)/2*height, 10, 10);
}

void draw() {

  if (beat.isKick())
    timeMult = 1.0;
  //} else {
  //  timeMult = 0.2;
  //}
  timeMult += (timeMultTarget - timeMult)*timeMultDamp;
  updateTime();

  updateDragging();

  //cube.render();

  background(0);
  hueShift.set("a", seconds()/timeSwitch(8*2, 2, 16, 64+16));//TWO_PI/(pow(2, 5 + 3*sin(seconds()))));
  hueShift.set("t", seconds()/8);
  hueShift.set("_t", _seconds());
  hueShift.set("mx", map(mouseX, 0, width, -1.0, 1.0));
  hueShift.set("my", map(mouseY, 0, height, -1.0, 1.0));
  hueShift.set("warpScale", abs(0.05*cos(_seconds()/8)));//map(mouseX, 0, width, 0, 0.15));
  hueShift.set("warpGrain", 1.0-abs(0.8*sin(_seconds()/8)));//map(mouseY, 0, height, 0.5, 0));
  hueShift.set("prevFrame", buffer);
  hueShift.set("Z1x", Z1.x);
  hueShift.set("Z1y", Z1.y);
  hueShift.set("Z2x", Z2.x);
  hueShift.set("Z2y", Z2.y);
  hueShift.set("Z3x", Z3.x);
  hueShift.set("Z3y", Z3.y);

  beat.detect(in.mix);

  float bigBeat = 100;
  float smallBeat = 25;

  rtarget = smallBeat;
  if (beat.isKick() || beat.isSnare()) {
    rvar = bigBeat;
  }

  rvar += (rtarget - rvar) / 6;
  pl.w = rvar;

  /*buffer.beginDraw();
   //sample buffer into four quads
   float angle = PI;
   float freq = 1.0/5;
   buffer.translate(width/2, height/2);
   buffer.pushMatrix();
   buffer.translate(-width/4, -height/4);
   buffer.scale(0.5);
   buffer.rotate(angle*sin(seconds()*freq));
   buffer.image(buffer, -buffer.width/2, -buffer.height/2);
   buffer.popMatrix();
   buffer.pushMatrix();
   buffer.translate(width/4, -height/4);
   buffer.scale(0.5);
   buffer.rotate(angle*sin(-seconds()*freq));
   buffer.image(buffer, -buffer.width/2, -buffer.height/2);
   buffer.popMatrix();
   buffer.pushMatrix();
   buffer.translate(-width/4, height/4);
   buffer.scale(0.5);
   buffer.rotate(angle*sin(-seconds()*freq));
   buffer.image(buffer, -buffer.width/2, -buffer.height/2);
   buffer.popMatrix();
   buffer.pushMatrix();
   buffer.translate(width/4, height/4);
   buffer.scale(0.5);
   buffer.rotate(angle*sin(seconds()*freq));
   buffer.image(buffer, -buffer.width/2, -buffer.height/2);
   buffer.popMatrix();
   buffer.endDraw();*/

  //buffer.beginDraw();
  //buffer.image(buffer, 0, 0);
  //buffer.endDraw();

  buffer.beginDraw();
  //if (beat.isSnare()) exclusionSwitch = !exclusionSwitch;
  if (exclusionSwitch) {
    buffer.blendMode(EXCLUSION);
  } else {
    buffer.blendMode(BLEND);
  }
  buffer.strokeWeight(10);
  buffer.stroke(255, 0, 0);
  buffer.fill(0, 0, 0, 50);
  //buffer.rect(0, 0, width, height);

  //drawCube();

  //buffer.rect(width/4, height/4, width/2, height/2);
  //buffer.ellipse(width/2, height/2, width, height);
  drawRectangle();

  drawGrid();  


  buffer.pushMatrix();
  //seed the epigram
  //buffer.translate(width/2, height/2);
  float tt = seconds()/3/3;
  //buffer.rotate(seconds()/32*-TWO_PI);
  //buffer.translate((width/8)*cos(tt), (height/8)*sin(tt));

  //buffer.rotate(TWO_PI*8*sin(seconds()/2));
  //buffer.rotate(-PI/2);
  //buffer.background(0, 255, 0);

  //pl.draw(buffer);
  drawSymbolGenerator();

  drawRecursionImage();

  buffer.popMatrix();


  //buffer.rotate(seconds());
  buffer.strokeWeight(3);
  //buffer.rotate(PI/2 + seconds());
  /*float wi = 50;
   int maxt = 200;
   for (int i = 0; i < maxt; i++) {
   buffer.rotate(PI/4*sin(seconds()/16 + 25 - 20*sin(seconds()/16)*float(i)/maxt));
   buffer.translate(wi/2, 0); 
   equiTriangle(wi, buffer);
   }*/
  /*for (int x = -3; x < 4; x++) {
   for (int y = -4; y < 5; y++) {
   float a = 50;
   float spx = 60 + 60*sin(seconds()*1); //spacing parameters
   float spy = 60 + 60*sin(seconds()*1); 
   float fx = x * (a/1.45 + spx);//x * a*((x)%2==1 ? sqrt(3)/4 : sqrt(3)/2.8) * cos(-PI/3) + y * a * cos(1.75*TWO_PI/3);
   float fy = y * (a*(sqrt(3)/4.5) + spy);//x * a*((x)%2==1 ? sqrt(3)/4 : sqrt(3)/2.8) * sin(-PI/3) + y * a * sin(1.75*TWO_PI/3);
   buffer.pushMatrix();
   float o = (((x+4) + (y+4)) % 2 == 1) ? a/4 : 0;
   buffer.translate(fx + o, fy);
   buffer.rotate((((x+4) + (y+4)) % 2 == 1) ? PI : 0);
   buffer.rotate(seconds());
   equiTriangle(a, buffer);
   buffer.popMatrix();
   }
   }*/

  buffer.filter(hueShift);

  //postProcessing.set("strength", 0.5*4000.0); //750
  //postProcessing.set("filterNumber", 7); //dilate
  //buffer.filter(postProcessing);
  //postProcessing.set("strength", 0.5*6000.0); //750
  //postProcessing.set("filterNumber", 8); //erode
  //buffer.filter(postProcessing);
  //postProcessing.set("strength", 1*8000.0); //200
  //postProcessing.set("filterNumber", 6); //sharpen
  //buffer.filter(postProcessing);
  //postProcessing.set("strength", 1000.0); //750
  //postProcessing.set("filterNumber", 4); //blur
  //buffer.filter(postProcessing);
  buffer.endDraw();

  /*pushMatrix();
   translate(0, 0, 700);
   
   pushMatrix();
   scale(float(width)/backgroundMov.width, float(height)/backgroundMov.height);
   image(backgroundMov, 0, 0);
   //image(backgroundMov, -backgroundMov.width/2, -backgroundMov.height/2);
   popMatrix();
   
   tint(255, 255.0*0.05);
   blendMode(SCREEN);
   //image(buffer, -buffer.width/2, -buffer.height/2);
   image(buffer, 0, 0);
   blendMode(BLEND);
   //cube.draw();
   popMatrix();*/

  //drawBackgroundMovie();
  skipBackgroundMovie();

  drawFinal();

  /*pushMatrix();
   translate(width/2, height/2, 500);
   bust.draw(buffer);
   popMatrix();*/

  pushMatrix();
  translate(width/2, height/2);
  //scale(0.5);
  //fill(255, 0, 0, 255);
  //rect(-256,-256,512,512);
  //cube.draw();
  popMatrix();

  drawMenuIcon();

  //pal.swap();

  //drawMobiusPoints();

  drawSplashScreen();
}

void drawSplashScreen() {
  if (splashScreenFirstDraw) {
    splashScreenTimerStart = 1*1000;
    splashScreenTimer = millis() + 2*1000 + splashScreenTimerStart;
    splashScreenFirstDraw = false;
  }
  if (splashScreenOn && millis() < splashScreenTimer) {
    pushMatrix();
    scale(float(width)/splashScreenImg.width, float(height)/splashScreenImg.height);
    tint(255, map(min(splashScreenTimer - millis(), splashScreenTimerStart), splashScreenTimerStart, 0, 255, 0));
    image(splashScreenImg, 0, 0);
    tint(255, 255);
    popMatrix();
  }
}

void drawCube() {
  buffer.pushMatrix();
  buffer.translate(width/2, height/2);
  float tz = seconds();
  buffer.translate(width/8*cos(tz), height/8*sin(tz));
  buffer.rotate(-seconds());
  buffer.scale(2);
  float q = sin(-seconds()/1);
  buffer.tint(255, min(255, max(0, map(q*q*q, -1, 1, -255, 255*2))));
  cube.draw(buffer);
  buffer.popMatrix();
}

void drawRectangle() {
  buffer.pushMatrix();
  buffer.noStroke();
  //buffer.translate(-width/2, -height/2);
  float layerSpeed = 1.0/8;
  //buffer.translate(width/2+width/2.3*cos(_seconds()*layerSpeed), height/2+height/2.3*cos(_seconds()*layerSpeed));
  //buffer.rotate(seconds()/16*TWO_PI);
  
  buffer.translate(width/2+100*cos(_seconds()*layerSpeed), height/2+100*cos(_seconds()*layerSpeed));
  //buffer.rotate(seconds()/32*TWO_PI);

  float geoBias = 0.5;//0.25+0.25*sin(seconds()/4);
  buffer.fill(255, 0, 0, geoBias*(bassBeat() ? 20 : 3));
  //buffer.fill(255, 0, 0, geoBias*(bassBeat() ? 150 : 75));
  buffer.rect(-width/2, -height/2, width, height);

  buffer.scale(0.5*float(width)/gradient.width, 0.5*float(height)/gradient.height);
  buffer.colorMode(HSB, 255);
  buffer.tint(color((seconds()*2*255)%255, 100, 255), 255*(1.0-geoBias));
  //buffer.image(gradient, -gradient.width/2, -gradient.height/2);
  buffer.colorMode(RGB, 255);

  buffer.popMatrix();
}

void drawGrid() {
  buffer.pushMatrix();
  buffer.translate(width/2, height/2);
  buffer.rotate(seconds()/32*-TWO_PI);
  buffer.scale(2);
  updateGrid();
  buffer.popMatrix();
}

void drawSymbolGenerator() {
  buffer.pushMatrix();
  float offset = 2*width*((_seconds()/32)%1);
  buffer.translate(width/2, height/2);
  buffer.rotate(_seconds()/16);
  buffer.pushMatrix();
  buffer.translate(-width + offset, 0);
  symbolGenerator.draw(buffer);
  buffer.popMatrix();
  buffer.pushMatrix();
  buffer.translate((width + offset)%(width*2)-width, 0);
  symbolGenerator.draw(buffer);
  buffer.popMatrix();
  buffer.popMatrix();
}

void drawRecursionImage() {
  int num = 3;
  float spinTiming = 0.05;
  float ringTiming = 0.1;
  for (int j = 0; j < numRecur; j++) {
    for (int i = 0; i < num; i++) {
      float f = float(i)/num*TWO_PI;
      float k = float(j)/numRecur*TWO_PI;
      float shrink = 0.75 + 0.5*(cos(_seconds()/8));
      float ringScale = sin(k+seconds()*ringTiming) * shrink;

      if (sin(k+seconds()*ringTiming) > 0.0) {
        buffer.pushMatrix();
        buffer.translate(width/2, height/2);
        buffer.rotate(seconds()*TWO_PI/7);
        buffer.scale(0.05*pow(2, 6*ringScale));
        //buffer.scale(ringScale);
        buffer.scale(0.5*float(height)/recur[j].img.width, 0.5*float(height)/recur[j].img.height);
        //buffer.tint(color(255, 255, 255-32), 255*pow(2, 3*ringScale));
        float slow = 64*4*4;
        float rates = (TWO_PI-PI/32);
        buffer.translate(height/(4*sin(seconds()/slow+k*rates*seconds()/slow))*3*ringScale*cos(f+seconds()*spinTiming), height/(4*sin(seconds()/slow+k*rates*seconds()/slow))*3*ringScale*sin(f+seconds()*spinTiming));
        recur[j].draw(f, buffer);
        buffer.popMatrix();
      }
    }
  }
}

void drawBackgroundMovie() {
  buffer2.beginDraw();
  buffer2.background(0);
  buffer2.pushMatrix();
  buffer2.scale(float(width)/backgroundMov.width, float(height)/backgroundMov.height);
  buffer2.image(backgroundMov, 0, 0);
  buffer2.popMatrix();
  buffer2.tint(255, 255.0*0.25);
  buffer2.blendMode(SCREEN);
  //image(buffer, -buffer.width/2, -buffer.height/2);
  buffer2.image(buffer, 0, 0);
  buffer2.blendMode(BLEND);
  buffer2.endDraw();
}

void skipBackgroundMovie() {
  buffer2.beginDraw();
  buffer2.background(0);
  buffer2.image(buffer, 0, 0);
  buffer2.endDraw();
}

void drawMenuIcon() {
  updateMenuIcon();
  pushMatrix();
  float scf = 0.2;
  translate(width - menuIcon.width*0.75*scf, height - menuIcon.height*0.75*scf);
  scale(scf);
  tint(255, min(255, menuIconVal));
  image(menuIcon, -menuIcon.width/2, -menuIcon.height/2);
  tint(255, 255);
  popMatrix();
}

void drawFinal() {
  pushMatrix();
  //translate(0, 0, 700);
  image(buffer2, 0, 0);
  popMatrix();
}

void updateMenuIcon() {
  if (mouseX != lastMouseX)
    menuIconVal = 255*2;
  lastMouseX = mouseX;
  menuIconVal += (menuIconTarget - menuIconVal) * menuIconDamp;
}

void updateGrid() {
  int tx = 15;
  int ty = 5;
  /*for (int i = 0; i < field.organization.elementCount; i++) {
   HexagonElement e = (HexagonElement)field.units.get(i);
   PVector p = field.organization.getTransformedPosition(i);
   //int ind = floor(p.y*buffer.height)*buffer.width + floor(p.x*buffer.width);
   //println(ind);
   //e.col = color((hue(pixels[ind])+(sin(seconds()*4)*32))%255, saturation(pixels[ind]), brightness(pixels[ind]));
   //e.SIZE = brightness(pixels[ind])/255*10;
   e.SIZE = 10.0;
   //e.CORNER = saturation(pixels[ind])/255;
   } */
  //buffer.pushMatrix();
  //buffer.translate(tx, ty);
  //buffer.blendMode(LIGHTEST);
  field.draw(buffer);
  field2.draw(buffer);
  //buffer.blendMode(BLEND);
  //buffer.popMatrix();
}

void equiTriangle(float a, PGraphics buffer) {
  float b = sqrt(3)/4;
  float c = a * b;
  buffer.triangle(c * cos(0), c * sin(0), c * cos(TWO_PI/3), c * sin(TWO_PI/3), c * cos(2*TWO_PI/3), c * sin(2*TWO_PI/3));
}

float timeSwitch(float len, float phase, float a, float b) {
  return (_seconds()+phase) % len < (len/2) ? a : b;
}

float _seconds() {
  return float(RAWTIME)/1000;
}

float seconds() {
  return float(TIME+5*60*1000)/1000.0;
}

void updateTime() {
  if (paused == false) {
    TIME += floor((millis() - lastTime)*timeMult);
    RAWTIME += floor(millis() - lastTime);
    lastTime = millis();
  }
}

float logistic(float x, float k) {
  return 1.0 / (1 + exp(-k * x));
}

boolean bassBeat() {
  return beat.isRange(0, 5, 3);
}

/*class BeatListener implements AudioListener
 {
 private BeatDetect beat;
 private AudioPlayer source;
 
 BeatListener(BeatDetect beat, AudioPlayer source)
 {
 this.source = source;
 this.source.addListener(this);
 this.beat = beat;
 }
 
 void samples(float[] samps)
 {
 beat.detect(source.mix);
 }
 
 void samples(float[] sampsL, float[] sampsR)
 {
 beat.detect(source.mix);
 }
 }*/

void renderSymbol() {
  eyeBuffer.beginDraw();
  eyeBuffer.translate(eyeBuffer.width/2, eyeBuffer.height/2);
  drawFrame();
  drawEye();
  eyeBuffer.endDraw();
}

void drawEye() {
  float r = 200;
  float edge = PI/6;
  eyeBuffer.stroke(255);
  eyeBuffer.fill(78, 48, 132);
  eyeBuffer.arc(0, -r*sin(edge)/2, r, r, edge, PI-edge);
  eyeBuffer.arc(0, r*sin(edge)/2, r, r, PI+edge, TWO_PI-edge);

  r *= 0.9;
  eyeBuffer.stroke(78, 48, 132);
  eyeBuffer.fill(255);
  eyeBuffer.arc(0, -r*sin(edge)/2, r, r, edge, PI-edge);
  eyeBuffer.arc(0, r*sin(edge)/2, r, r, PI+edge, TWO_PI-edge);

  eyeBuffer.noStroke();
  eyeBuffer.fill(40, 10, 40);
  eyeBuffer.ellipse(0, 0, r/2.1, r/2.1);

  eyeBuffer.fill(167, 252, 0);
  eyeBuffer.ellipse(0, 0, r/2.5, r/2.5);

  eyeBuffer.fill(40, 10, 40);
  eyeBuffer.ellipse(0, 0, r/4, r/4);

  eyeBuffer.fill(255);
  eyeBuffer.ellipse(r/16, -r/16, r/8, r/8);
}

void drawFrame() {
  float p = 150;
  float r = 75;
  eyeBuffer.fill(120, 81, 169); 
  eyeBuffer.stroke(255);
  eyeBuffer.strokeWeight(7);
  eyeBuffer.line(-p, 0, 0, -p);
  eyeBuffer.line(0, -p, p, 0);
  eyeBuffer.line(p, 0, 0, p);
  eyeBuffer.line(0, p, -p, 0);
  eyeBuffer.ellipse(0, p, r, r);
  eyeBuffer.ellipse(-p, 0, r, r);
  eyeBuffer.ellipse(p, 0, r, r);
  eyeBuffer.ellipse(0, -p, r, r);
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

/*
https://www.youtube.com/watch?v=6eQKXtte6mY
 */
