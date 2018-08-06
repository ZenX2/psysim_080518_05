class Palette {
 ArrayList<Integer> colors;
 PShader shd;
 
 //color primary(), secondary(), tertiary() (??????)
 
 Palette() {
   colors = new ArrayList<Integer>();
   shd = loadShader("PaletteSwap.glsl");
 }
 
 void addColor(color c) {
   colors.add(c); 
 }
 
 void initShader() {
   float[] r = new float[colors.size()];
   float[] g = new float[colors.size()];
   float[] b = new float[colors.size()];
   for(int i = 0; i < colors.size(); i++) {
     r[i] = red(colors.get(i))/255.0;
     g[i] = green(colors.get(i))/255.0;
     b[i] = blue(colors.get(i))/255.0;
   }
   shd.set("R", r);
   shd.set("G", g);
   shd.set("B", b);
   shd.set("numColors", colors.size());
 }
 
 void swap() {
   initShader();
   filter(shd);
 }
 
 void swap(PGraphics buffer) {
   initShader();
   buffer.filter(shd);
 }
 
 color sample(float x) { //[0,1]
   float big = x*(colors.size()-1);
   int intPart = floor(big);
   float fracPart = big % 1.0;
   color A = colors.get(intPart);
   if (colors.size() > intPart+1) {
     color B = colors.get(intPart+1);
     PVector finalCol = PVector.add(
       PVector.mult(new PVector(red(A), green(A), blue(A)), 1.0-fracPart),
       PVector.mult(new PVector(red(B), green(B), blue(B)), fracPart));
     return color(finalCol.x, finalCol.y, finalCol.z);
   } else {
     return A;
   }
}
 
 void draw(float w, float h) {
   for (int i = 0; i < colors.size(); i++) {
     color c = colors.get(i);
     float p = float(i)/colors.size();
     fill(c);
     noStroke();
     rect(p*w, 0, w/colors.size(), h);
   }
 }
}
