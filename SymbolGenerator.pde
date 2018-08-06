class SymbolGenerator {
  ArrayList<Entity> entities;
  PGraphics buffer;
  int res = 128;
  int scr_res = 512;
  int cells[];
  ArrayList<PVector> cellColors;
  boolean showEntities = false;

  SymbolGenerator() {
    entities = new ArrayList<Entity>();
    buffer = createGraphics(width, height, P2D);
    buffer.beginDraw();
    //buffer.background(0);
    buffer.endDraw();

    scr_res = width;
    cells = new int[res*res];
    cellColors = new ArrayList<PVector>();
    //cellColors.add(new PVector(128, 064, 000)); //0 Dirt, brown
    cellColors.add(new PVector(3, 3, 3)); //0 Dirt, brown
    cellColors.add(new PVector(0, 50, 150)); //1 River, blue
    cellColors.add(new PVector(0, 50, 150)); //2 RiverSource, blue
    cellColors.add(new PVector(0, 150, 25)); //3 Grass, green
    cellColors.add(new PVector(200, 200, 200)); //4 Road, grey
  }



  void genRoadLayers(int num) {
    int sc = scr_res / res;
    for (int i = 0; i < num; i++) {
      new RoadLayer(mouseX/sc, mouseY/sc);
    }
  }

  int getCell(int _x, int _y) { //wrap-around is neighbors, for simplicity's sake
    int x = (_x + res)%res;
    int y = (_y + res)%res;
    int i = x + y * res;
    return cells[i];
  }

  void setCell(int _x, int _y, int type) { //wrap-around is neighbors, for simplicity's sake
    int x = (_x + res)%res;
    int y = (_y + res)%res;
    int i = x + y * res;
    cells[i] = type;
  }

  void drawCell(int x, int y, int type) {
    buffer.noStroke();
    PVector col = cellColors.get(type);

    if (type!=4) return;

    buffer.colorMode(HSB, 255);
    float nscx = 64.0;
    float nscy = 64.0;
    buffer.fill((map(noise(x/nscx, y/nscy, seconds()/4), 0, 1, 0, 255) + (32)*seconds()) % 255, 200, 220);
    buffer.colorMode(RGB, 255);

    int sc = scr_res / res;
    //buffer.stroke(0, 0, 0, 10);
    buffer.rect(x*sc, y*sc, sc, sc);
  }

  void drawCellBoundary(int x, int y, int type) {
    if (type!=4) return;
    noFill();
    noStroke();
    int sc = scr_res / res;
    //stroke(100, 100, 0, 30);
    colorMode(HSB, 255);
    float nscx = 64.0;
    float nscy = 64.0;
    fill((map(noise(x/nscx, y/nscy, seconds()/4), 0, 1, 0, 255) + 32+16 + (32)*seconds()) % 255, 200, 220);
    colorMode(RGB, 255);
    rect(x*sc, y*sc, sc, sc);
  }

  void drawCell(int x, int y, PVector col) {
    buffer.noStroke();
    buffer.fill(col.x, col.y, col.z);
    int sc = scr_res / res;
    buffer.rect(x*sc, y*sc, sc, sc);
  }

  int updateCell(int x, int y, int i) {
    //Check senses to determine actions
    if (cells[i] == 0) { //Dirt
      /*if (getCell(x-2, y) == 4 && getCell(x-1, y) == 4 && getCell(x+1, y) != 4) {
       return 4;
       }
       if (getCell(x+2, y) == 4 && getCell(x+1, y) == 4 && getCell(x-1, y) != 4) {
       return 4;
       }
       if (getCell(x, y-2) == 4 && getCell(x, y-1) == 4 && getCell(x, y+1) != 4) {
       return 4;
       }
       if (getCell(x, y+2) == 4 && getCell(x, y+1) == 4 && getCell(x, y-1) != 4) {
       return 4;
       }
       if ((getCell(x-1, y) == 4 || getCell(x+1, y) == 4 || getCell(x, y-1) == 4 || getCell(x, y+1) == 4) && random(10000) < 0.1) {
       return 4;
       }*/
    }
    if (cells[i] == 4) {
      int sum = 0;
      /*if (getCell(x-1, y) == 4) sum++;
       if (getCell(x+1, y) == 4) sum++;
       if (getCell(x, y+1) == 4) sum++;
       if (getCell(x, y-1) == 4) sum++;
       if (sum > 3)
       return 0;
       sum = 0;*/
      if (getCell(x-1, y-1) == 4) sum++;
      if (getCell(x+1, y-1) == 4) sum++;
      if (getCell(x-1, y+1) == 4) sum++;
      if (getCell(x+1, y+1) == 4) sum++;
      int limit = noise(x/128.0, y/128.0, seconds()) < 0.5 ? 4 : 2;
      if (sum > limit)
        return 0;

      if ((getCell(x-2, y) == 4 && getCell(x+2, y) == 4 && getCell(x-2, y+1) == 4 && getCell(x+2, y+1) == 4 && getCell(x-2, y-1) == 4 && getCell(x+2, y-1) == 4) ||
        (getCell(x, y-2) == 4 && getCell(x, y+2) == 4 && getCell(x+1, y-2) == 4 && getCell(x+1, y+2) == 4 && getCell(x-1, y-2) == 4 && getCell(x-1, y+2) == 4)) {
        return 0;
      }

      int w = 4;
      int h = 4;
      int ws = 3;
      int hs = 6;
      if (x % (w+ws) > w || y % (h+hs) > h) return 0;
    }
    return cells[i];
  }

  /*interface Cell {
   //int type;
   }
   
   enum CellTypes {
   DIRT, 
   RIVER, 
   RIVERSOURCE, 
   GRASS, 
   ROAD
   }*/

  void draw(PGraphics destination) {
    for (Entity e : entities) {
      e.update();
    }
    int newCells[] = new int[res*res];
    for (int y = 0; y < res; y++) {
      for (int x = 0; x < res; x++) {
        int i = x + y * res;
        newCells[i] = updateCell(x, y, i);
      }
    }
    for (int y = 0; y < res; y++) {
      for (int x = 0; x < res; x++) {
        int i = x + y * res;
        cells[i] = newCells[i];
      }
    }

    buffer.beginDraw();
    buffer.clear();
    //buffer.image(buffer, 0, 0);
    //buffer.fill(0, 0, 0, 30);
    //buffer.rect(0, 0, width, height);
    //buffer.mask(myMask);

    for (int y = 0; y < res; y++) {
      for (int x = 0; x < res; x++) {
        int i = x + y * res;
        drawCell(x, y, cells[i]);
      }
    }
    //warping.set("power", 0.01);
    //buffer.filter(warping);
    buffer.endDraw();
    if (showEntities) {
      for (Entity e : entities) {
        e.draw();
      }
    }
    if (destination != null) {
      destination.image(buffer, -buffer.width/2, -buffer.height/2);
    } else {
      image(buffer, 0, 0);
    }
    /*for (int y = 0; y < res; y++) {
     for (int x = 0; x < res; x++) {
     int i = x + y * res;
     //drawCellBoundary(x, y, cells[i]);
     }
     }*/
  }

  abstract class Entity {
    int id;
    int x;
    int y;

    Entity(int _x, int _y) {
      x = _x;
      y = _y;
      id = entities.size();
      entities.add(this);
    }

    abstract void update();
    abstract void draw();

    void delete() {
      //onDelete();
      entities.remove(this);
    }
    //abstract void onDelete();
  }

  class RoadLayer extends Entity {
    int dir = 0;

    RoadLayer(int x, int y) {
      super(x, y);
      dir = floor(random(4));
    }

    void setDir(int d) {
      dir = (d + 4) % 4;
    }

    PVector dirVector(int d) {
      if (d == 0) {
        return new PVector(1, 0);
      } else if (d == 1) {
        return new PVector(0, 1);
      } else if (d == 2) {
        return new PVector(-1, 0);
      } else if (d == 3) {
        return new PVector(0, -1);
      }
      return new PVector(0, 0);
    }

    void update() {
      PVector d = dirVector(dir);
      setCell(x, y, (seconds()+id) % 4 > 2 ? 4 : 0); //place road where you are

      int flip = (seconds() % 10 < 5) ? 1 : -1;

      int turnCount = 0;
      if (getCell(x + floor(d.x), y + floor(d.y)) == 4) {
        while (getCell(x + floor(d.x*2), y + floor(d.y*2)) == 4 && turnCount < 1) {
          setDir(dir + flip * (random(10)<3 ? 1 : -1)); 
          turnCount++;
        }
      } else if (random(100) < 5) {
        setDir(dir + flip * (random(10)<8 ? 1 : -1));
      }

      d = dirVector(dir);
      x += d.x;
      y += d.y;
      x = (x + res) % res;
      y = (y + res) % res;
    }

    void draw() {
      drawCell(x, y, new PVector(0, 255, 0));
    }
  }
}

/*int turnCount = 0;
 if (getCell(x + floor(d.x*2), y + floor(d.y*2)) == 4) {
 while (getCell(x + floor(d.x*2), y + floor(d.y*2)) == 4 && turnCount < 10) {
 setDir(dir + (random(10)<5 ? 1 : -1)); 
 turnCount++;
 }
 } else if (random(100) < 1) {
 setDir(dir + (random(10)<5 ? 1 : -1));
 }*/
