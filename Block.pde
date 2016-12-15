class Block {
  PImage [] blocks=new PImage[4];
  int size;
  int [][] brick;
  int [][] brickCount;  //出現までの時間を計る
  int area;
  Block(int m, int s) {
    //mは背景を何枚分使うかの枚数。ステージの長さ
    size = s;
    blocks[0]=loadImage("block1.png");
    blocks[1]=loadImage("block2.png");
    blocks[2]=loadImage("block3.png");
    blocks[3]=loadImage("broken.png");
    brick = new int[20*m][6];
    brickCount = new int[20*m][6];
    area=0;

    for (int i=0; i<brickCount.length; i++) {
      for (int j=0; j<6; j++) {
        brick[i][j] = 0;
        brickCount[i][j] = 0;
      }
    }
  }


  int isFloor(int _x, int _y) {

    int x=_x/(size);
    int y;
    if (x>=brick.length) {
      return height-size*3;
    }
    if (_y>size*3) {
      y=_y/(size)-3;
    } else {
      y=-1;
    }
    for (int i=y; i<5; i++) {
      if (brick[x][i+1]>=1 && brickCount[x][i+1]==0) {
        int tmp=(i+3)*size;
        return tmp;
      }
    }
    return height-size*3;
  }

  int isTop(int _x, int _y) {
    if (_y<size*3) {
      return 0;
    }
    int []chara=squares(_x, _y);
    int x=chara[0];
    int y=chara[1];
    if (x>=brick.length) {
      return 0;
    }
    if (y==-1||y==6) {
      return 0;
    } else {
      if (brickCount[x][y]>0) {
        return 0;
      }
      return brick[x][y];
    }
  }

  boolean isBlock(int _x, int _y) {
    int []chara=squares(_x, _y);
    int x=chara[0];
    int y=chara[1];
    if (x>=brick.length || x<0) {
      return false;
    }
    if (y==-1||y==6) {
      return false;
    } else {
      if (brick[x][y]==0 || brickCount[x][y]>0) {
        return false;
      } else {
        return true;
      }
    }
  }

  void loadFromFile() {  
    //ファイルをロード
    String [] lines=loadStrings("data.csv");
    if (lines != null) {
      for (int j=0; j<6; j++) {
        String [] data = split(lines[j], ',');
        for (int i=0; i<brick.length; i++) {
          if (data.length<=i) {
            brick[i][j]=0;
          } else {
            brick[i][j]=int(data[i]);
          }
        }
      }
    }
  }

  void getSerialData_(String inString) {
    //文字列データをbrickに入れる


    //println("inString="+inString);

    String lines[] = split(inString, '/'); 
    try {
      for (int j=0; j<lines.length; j++) {
        lines[j]=trim(lines[j]);
        int data[] = int(split(lines[j], ',') );

        for (int i=0; i<data.length; i++) {
          if (brick[j+10*area][i]<=0 || data[i]<=0) {
            brick[j+10*area][i] = data[i];
          }
        }
      }
    }
    catch(Exception e) {
      //println(e);
    }
  }



  void getSerialData_battle(String inString) {
    //文字列データをbrickに入れる（対戦用）
    //println("inString="+inString);
    String lines[] = split(inString, '/'); 
    try {
      for (int j=0; j<lines.length; j++) {
        lines[j]=trim(lines[j]);
        int data[] = int(split(lines[j], ',') );
        for (int i=0; i<data.length; i++) {
          if (brick[int(j+10*0.5)][i]<=0 || data[i]<=0) {
            brick[int(j+10*0.5)][i] = data[i];
            brickCount[int(j+10*0.5)][i] = 30;
            int k = (int)random(5);
            if (k<=1 && data[i]==1) {
              brick[int(j+10*0.5)][i] = 2;
            }
          }
        }
      }
    }
    catch(Exception e) {
      //println(e);
    }
  }

  //出現までのカウントダウン用
  void countDown() {
    for (int i=0; i<brickCount.length; i++) {
      for (int j=0; j<6; j++) {
        if (brick[i][j]==0) {
          brickCount[i][j] = 30;
        } else {
          brickCount[i][j]--;
        }
      }
    }
  }


  void saveToFile() {
    //ファイルにセーブ
    String [] lines = new String[6];
    for (int j=0; j<6; j++) {
      String [] data = new String[brick.length];
      for (int i=0; i<brick.length; i++) {
        data[i]=str(brick[i][j]);
      }
      lines[j]=join(data, ',');
    }
    saveStrings("data.csv", lines);
  }

  int[] squares(int _x, int _y) {
    //キャラ座標をマス目に変換する用
    int x=_x/size;
    int y;
    if (_y>size*3 && _y<height-size*3) {
      y=_y/size-3;
    } else if (_y<size*3) {
      y=6;
    } else {
      y=-1;
    }
    int []vector= {
      x, y
    };
    return vector;
  }


  void display() {
    //描画
    for (int i=0; i<brick.length; i++) {
      for (int j=0; j<6; j++) {
        if (brick[i][j]>0 && brickCount[i][j]<=0) {
          int bufx=0, bufy=0;
          if (brickCount[i][j]<0) {
            bufx = int(random(0.5)*brickCount[i][j]/10);
            bufy = int(random(0.5)*brickCount[i][j]/10);
          }
          image(blocks[brick[i][j]-1], i*size+bufx, (j+3)*size+bufy, size, size);
        } else if (brick[i][j]>0 && brickCount[i][j]>0) {
          tint(255, 150);
          image(blocks[brick[i][j]-1], i*size, (j+3)*size, size, size);
          noTint();
        }
      }
    }
  }
}