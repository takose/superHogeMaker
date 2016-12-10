class Bullet {
  int posX, posY, firX;
  int speedX, time;
  PImage img;
  boolean right;

  Bullet(int x, int y, int num, boolean r) {
    n = num;
    posX = x;
    posY = y;
    firX = x;  //初期位置を保存
    speedX = 2;
    time = 0;
    right = r;

    img = loadImage("bullet2.png");
  }

  void move() {
    time++;
    if (time>2) {  
      if (right) {
        posX = posX+speedX*n;
      } else {
        posX = posX-speedX*n;
      }
    }
  }

  void display() {
    if (time>4) {
      image(img, posX, posY, img.width*n, img.height*n);
    }
  }
}