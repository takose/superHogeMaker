class Block {
  PImage [] blocks=new PImage[4];
  int [][] brick;
  int [][] brickCount;  //出現までの時間を計る
  int n;  //拡大倍率
  int area;
  Block(int m, int num) {
    //mは背景を何枚分使うかの枚数。ステージの長さ
    //numは拡大倍率

    blocks[0]=loadImage("block1.png");
    blocks[1]=loadImage("block2.png");
    blocks[2]=loadImage("block3.png");
    blocks[3]=loadImage("broken.png");
    n=num;
    brick = new int[20*m][6];
    brickCount = new int[20*m][6];
    area=0;
  }


  int isFloor(int _x, int _y) {

    int x=_x/(16*n);
    int y;
    if (x>=brick.length) {
      return height-48*n;
    }
    if (_y>16*n*3) {
      y=_y/(16*n)-3;
    } else {
      y=-1;
    }
    for (int i=y; i<5; i++) {
      if (brick[x][i+1]>=1) {
        int tmp=(i+3)*16*n;
        return tmp;
      }
    }
    return height-48*n;
  }

  int isTop(int _x, int _y) {
    if (_y<16*n*3) {
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
      return brick[x][y];
    }
  }

  boolean isRight(int _x, int _y) {
    int []chara=squares(_x, _y);
    int x=chara[0];
    int y=chara[1];
    if (x>=brick.length || x<0) {
      return false;
    }
    if (y==-1||y==6) {
      return false;
    } else {
      if (brick[x][y]==0) {
        return false;
      } else {
        return true;
      }
    }
  }

  boolean isLeft(int _x, int _y) {
    int []chara=squares(_x, _y);
    int x=chara[0];
    int y=chara[1];
    if (x>=brick.length || x<0) {
      return false;
    }
    if (y==-1||y==6) {
      return false;
    } else {
      if (brick[x][y]==0) {
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

        //println(data[0]+", "+data[1]);


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
            int k = (int)random(3);
            if (k==0 && data[i]==1) {
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
        brickCount[i][j]--;
        if (brickCount[i][j]<0) {
          brickCount[i][j] = 0;
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
    int x=_x/(16*n);
    int y;
    if (_y>16*n*3 && _y<height-48*n) {
      y=_y/(16*n)-3;
    } else if (_y<16*n*3) {
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
        if (brick[i][j]>0 && brickCount[i][j]==0) {
          image(blocks[brick[i][j]-1], i*16*n, (j+3)*16*n, 16*n, 16*n);
        } else if (brick[i][j]>0 && brickCount[i][j]>0) {
          tint(255, 150);
          image(blocks[brick[i][j]-1], i*16*n, (j+3)*16*n, 16*n, 16*n);
          noTint();
        }
      }
    }
  }
}