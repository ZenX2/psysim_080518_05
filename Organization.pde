abstract class Organization {
  int elementCount;
  PVector translation = new PVector(0, 0);
  PVector scaling = new PVector(1, 1);
  
  abstract PVector gridFunc(int i);
  
  PVector transform(PVector p) {
    return new PVector((p.x-0.5) * scaling.x + translation.x, (p.y-0.5) * scaling.y + translation.y);
  }
  
  PVector getPosition(int i) {
    return gridFunc(i);
  }
  
  PVector getTransformedPosition(int i) {
    return transform(gridFunc(i));
  }
}

class SquareGrid extends Organization {
  int w, h;
  
  SquareGrid(int _w, int _h) {
    w = _w;
    h = _h;
    elementCount = w*h;
  }
  
  PVector gridFunc(int i) {
    int x = i % w;
    int y = (i-x)/w;
    PVector ou = new PVector(float(x)/w, float(y)/h);
    return ou;
  }
}

class DiamondGrid extends Organization {
  int w, h;
  
  DiamondGrid(int _w, int _h) {
    w = _w;
    h = _h;
    elementCount = w*h;
  }
  
  PVector gridFunc(int i) {
    int x = i % w;
    int y = (i-x)/w;
    PVector ou = new PVector(float(x)/w, float(y)/h);
    if (x % 2 == 0) {
      ou.y += -1.0/h/4;
    } else {
      ou.y += 1.0/h/4;
    }
    return ou;
  }
}
