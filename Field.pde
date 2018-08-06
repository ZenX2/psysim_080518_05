class Field {
  ArrayList<Element> units;
  Organization organization;
  
  Field(Organization _org) {
    units = new ArrayList<Element>();
    organization = _org;
  }
  
  void addElement(Element e) {
    units.add(e);
  }
  
  void draw() {
    for (int i = 0; i < organization.elementCount; i++) {
      Element e = units.get(i);
      e.update(organization.getPosition(i));
      
      PVector p = organization.getTransformedPosition(i);
      pushMatrix();
      translate(p.x, p.y);
      e.draw();
      popMatrix();
    }
  }
  
  void draw(PGraphics buffer) {
    for (int i = 0; i < organization.elementCount; i++) {
      Element e = units.get(i);
      e.update(organization.getPosition(i));
      
      PVector p = organization.getTransformedPosition(i);
      buffer.pushMatrix();
      buffer.translate(p.x, p.y);
      e.draw(buffer);
      buffer.popMatrix();
    }
  }
}
