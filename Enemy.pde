class Enemy extends Player {
  PImage[] EEX = new PImage [3];

  Enemy(int ex, int ey) {
    super(ex, ey);
    EEX[0] = loadImage("processing_violet.png");
    EEX[1] = loadImage("processing_violet2.png");
    EEX[2] = loadImage("processing_violet3.png");
  }

  void draw() {
    if (!alive) {
      image(EEX[2], posX, posY, 16*n, 16*n);
    } else if (touch==true) {
      image(EEX[time%2], posX, posY, 16*n, 16*n);
    } else {
      image(EEX[0], posX, posY, 16*n, 16*n);
    }
  }
}

