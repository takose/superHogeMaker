class Item {
  int posX, posY;
  PImage img;
  int n,kind;

  Item(int x, int y, int num, int _kind) {
    n=num;
    posX=x*16*n;
    posY=y*16*n+32*n;
    kind = _kind;
    switch(kind){
      case 0:
        img=loadImage("stone.png");
      break;
      case 1:
        img=loadImage("amethyst.png");
      break;
      default:
      break;
    }
    kind = _kind;
  }

  void display() {
    image(img, posX, posY, 16*n, 16*n);
  }

  boolean isItem(int _x, int _y) {
    //キャラとのあたり判定用
    if (dist(_x, _y, posX+8*n, posY+8*n)<=12*n) {
      return true;
    }
    return false;
  }
}