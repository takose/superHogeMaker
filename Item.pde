class Item {
  int posX, posY;
  PImage bird;
  int n;

  Item(int x, int y, int num) {
    n=num;
    posX=x*16*n;
    posY=y*16*n+32*n;
    bird=loadImage("yellowbird.png");
  }

  void display() {
    image(bird, posX, posY, 16*n, 16*n);
  }

  boolean isItem(int _x, int _y) {
    //キャラとのあたり判定用
    if (dist(_x, _y, posX+8*n, posY+8*n)<=12*n) {
      return true;
    }
    return false;
  }
}