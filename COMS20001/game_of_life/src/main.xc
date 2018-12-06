// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
#include "../lib_i2c/api/i2c.h"
#include <timer.h>
#include <string.h>
#include <assert.h>

#define  IMHT 16           //image height
#define  IMWD 16                //image width
#define WORKERS 8

typedef unsigned char uchar;      //using uchar as shorthand
typedef unsigned short ushor;       //using ushor as shorthand

on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to orientation
on tile[0]: port p_sda = XS1_PORT_1F;

on tile[0] : in port buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0] : out port leds = XS1_PORT_4F;   //port to access xCore-200 LEDs

#define FXOS8700EQ_I2C_ADDR 0x1E  //register addresses for orientation
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6

//Function Prototypes
int noOfLiveNeighbours(char image[3][IMHT/8], int i, int j);
uchar gameOfLifeLogic(char image[IMWD/WORKERS + 2][IMHT/8], int i, int k, int j);


uchar packBits(uchar newBit, int position, uchar returnByte){
    uchar val = newBit & 0x01;
    returnByte |= (val << (7-position));
    return returnByte;
}

uchar unpackBits(uchar byte, int pos){
    uchar bit = (byte >> (7-pos)) & 0x01;
    return bit;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Functions for the Game of Life logic
//
/////////////////////////////////////////////////////////////////////////////////////////
// row, byte, pos in the byte
uchar gameOfLifeLogic(uchar image[IMWD/WORKERS + 2][IMHT/8], int i, int k, int j) {
    int l_neighbours =0;
    uchar simplifiedImage[3][IMHT/8];
    int prevRow = i-1;
    int row = i;
    int nextRow = i+1;

    // get the three lines
    for (int x = 0; x<3; x++){
        for (int y=0; y<IMHT/8; y++){
            if (x == 0){
                simplifiedImage[x][y]=image[prevRow][y];
            }
            else if (x == 1){
                simplifiedImage[x][y]=image[row][y];
            }
            else if (x == 2){
                simplifiedImage[x][y]=image[nextRow][y];
            }
        }
    }
//----------------------------------------------------------------------------------------------
    l_neighbours = noOfLiveNeighbours(simplifiedImage, k , j);

    //cell is live
    if (unpackBits(image[i][k],j) == 1) {
        //any live cell with fewer than two live neighbours dies
        if ( l_neighbours<2 ) {
            return (uchar)0x00;
        }
        //any live cell with two or three live neighbours is unaffected
        else if (( l_neighbours==2 )||( l_neighbours==3 )) {
            return (uchar)0xFF;
        }
        //any live cell with more than three live neighbours dies
        else if ( l_neighbours>3 ) {
            return (uchar)0x00;
        }
    }
    //cells are dead
    else if (unpackBits(image[i][k],j) == 0) {
        //any dead cell with exactly three live neighbours becomes alive
        if ( l_neighbours==3 ) {
            return (uchar)0xFF;
        }
        else {
           return (uchar)0x00;
        }
    }
    return 0;
}

// send image of three rows for that cell to check no. of alive neighbours
// i: byte, j:pos
int noOfLiveNeighbours(uchar image[3][IMHT/8], int i, int j) {
    int live_n =0;
    int leftBytePos = i;
    int rightBytePos = i;
    int right = j+1;
    int left = j-1;

    // if cell is first in byte, then go to previous
    if (left == -1){
        left = 7;
        if (leftBytePos == 0){
            leftBytePos = IMHT/8 - 1;
        }
        else leftBytePos = leftBytePos -1;
    }
    if (right == 8){
       right = 0;
       if (rightBytePos == IMHT/8 - 1){
           rightBytePos = 0;
       }
       else rightBytePos = rightBytePos +1;
    }
 /* ---------------------------------------------------------------- */
    if (unpackBits(image[1][rightBytePos], right)==0x01){ //right side
        live_n++;
    }
    if (unpackBits(image[1][leftBytePos], left)==0x01) //left side
        live_n++;

    if (unpackBits(image[0][i], j)==0x01){ //top
        live_n++;
    }
    if (unpackBits(image[2][i], j)==0x01){ //bottom
        live_n++;
    }
    if (unpackBits(image[0][rightBytePos], right)==0x01) //top right
        live_n++;

    if (unpackBits(image[0][leftBytePos], left)==0x01) //top left
        live_n++;

    if (unpackBits(image[2][rightBytePos], right)==0x01)  //bottom right
        live_n++;

    if (unpackBits(image[2][leftBytePos], left)==0x01)  //bottom left
        live_n++;

  return live_n;
}

int totalLiveCells(uchar image[IMWD][IMHT/8]){
    int live = 0;
    for (int i=0; i<IMWD; i++) {
        for (int j=0; j<IMHT/8; j++) {
            for (int k=0; k<8; k++)
            if (unpackBits(image[i][j], k)==0x01)
              live++;
        }
    }
    return live;
}

void tests(){
    assert(packBits(0x00, 0, 0x00) == 0x00);
    assert(packBits(0x01, 0, 0x00) == 0x80);
    assert(packBits(0xFF, 3, 0x00) == 0x10);

    assert(unpackBits(0xE6, 0) == 1);
    assert(unpackBits(0xE6, 1) == 1);
    assert(unpackBits(0xE6, 4) == 0);

    /*uchar test[3][2];

    test[0][0]=0; test[1][0]=132; test[2][0]=64;
    test[0][1]=32; test[1][1]=113; test[2][1]=64;


    assert(noOfLiveNeighbours(test, 0, 5) == 0);
    assert(noOfLiveNeighbours(test, 1, 2) == 4);
    assert(noOfLiveNeighbours(test, 0, 0) == 2);
    assert(noOfLiveNeighbours(test, 1, 7) == 1);

    uchar test2[3][2];
    test2[0][0]=8; test2[1][0]=4; test2[2][0]=28;
    assert(noOfLiveNeighbours(test2, 0, 4) == 5);

    uchar test3[3][2];
    test3[0][0]=0; test3[1][0]=8; test3[2][0]=4;
    assert(noOfLiveNeighbours(test3, 0, 4) == 1);

    //test total no of live cells
    uchar test1[16][16];

    for(int l=0; l<16; l++){
        for(int m=0; m<2; m++){
            test1[l][m]=0;
        }
    }*/
    printf("PASSED ASSERTS\n");
}

// Represents each worker
// Receives the image to be worked on
// Sends the resulting value of each cell to the collector
void worker(chanend toCollect, chanend fromDist){
    uchar new_val;
    uchar byte = 0x00;
    uchar image[IMWD/WORKERS + 2][IMHT/8];
    int pause = 9;

    while (1){
        // get image
        fromDist :> pause;
        if(pause == 9){
            // receives image
            for( int y = 1; y < IMWD/WORKERS + 1; y++ ) {   //go through all lines
                for( int x = 0; x < IMHT/8; x++ ) { //go through each pixel per line
                   fromDist :> image[y][x];
                }
              }
            // receive two extra lines
            for (int a=0; a< IMHT/8; a++){
                fromDist :> image[0][a];
            }
            for (int b=0; b< IMHT/8; b++){
                fromDist :> image[IMWD/WORKERS + 1][b];
            }
            // for each row sent that the worker should process
            for (int  i=1 ; i<IMHT/WORKERS+1 ; i++){
                // performs the logic on each bit in a byte of each row
                for(int k = 0; k < IMHT/8; k++){
                    for (int j=0; j<8; j++){
                        // i: the row, k: the byte in that row, j: the position of the bit
                        new_val = gameOfLifeLogic(image, i,k,j);
                        byte = packBits(new_val, j, byte);
                    }
                    toCollect <: byte;
                    byte = 0x00;
                }
            }
        }
    }
} //end of worker()

// Collects data from each worker and sends to distributor for nexy round
void collector(chanend fromWorker[WORKERS], chanend toDistributor){
    uchar val;
    char newImage[IMWD][IMHT/8];
    int rowCount;
    int sig = 0;

    while (1){
        rowCount = 0;
        toDistributor <: 3;
        // what is this:  for each worker
        for (int i=0; i<WORKERS; i++){
            // get the number of row assigned to that worker
            for (int k=0; k<IMHT/WORKERS; k++){
                // number of bytes for each worker process
                for (int j=0; j<IMHT/8; j++){
                    //for (int count = 0 ; count < 8; count++){
                        fromWorker[i] :> val;
                        newImage[k + i*(IMHT/WORKERS) ][j] = val;
                }
           }
        }
        toDistributor :> sig;
        if (sig == 2){
            // After collecting we send to the distributor
                    toDistributor <: 2;
                    for(int y = 0; y<IMWD; y++){
                        for(int x = 0; x<IMHT/8; x++){
                            toDistributor <: newImage[y][x];
                        }
                    }
        }
    }
}


void buttonListener(in port fromButton, chanend toDistributor) {
  int x;
  while (1) {
    fromButton when pinseq(15)  :> x;    // check that no button is pressed
    fromButton when pinsneq(15) :> x;    // check if some buttons are pressed
    if ((x == 13) || (x == 14))     // if either button is pressed
        toDistributor <: x;             // send button pattern to distributor
  }
}

//calculates the time in seconds and sends it to distributor when asked
void calcTime(chanend fromDistributor){
    timer t;
    uint32_t curTime;
    int totalSeconds = 0, val = 0;
    const uint32_t SECOND = 100000; //represents 1 second

    t :> curTime;
    fromDistributor :> val;
    while (1) {
        select {
            case t when timerafter(curTime) :> void:
                totalSeconds++;
                curTime+=SECOND; //adding a second to the current time
                break;

            case fromDistributor :> val:
                if(val == 3) { //send value to distributor when asked
                    fromDistributor <: totalSeconds;
                }
                fromDistributor :> val;
                t :> curTime;
                break;
        }
    }
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from PGM file from path infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out)
{
  int res;
  uchar line[ IMWD ];
  uchar byte = 0x00;
  printf( "DataInStream: Start...\n" );

  //Open PGM file
  res = _openinpgm( infname, IMWD, IMHT );
  if( res ) {
    printf( "DataInStream: Error openening %s\n.", infname );
    return;
  }

  //Read image line-by-line and send byte by byte to channel c_out
  for( int y = 0; y < IMHT; y++ ) {
    _readinline( line, IMWD );
    // printf("LINE READ %d\n", y);
    for( int x = 0; x < IMWD/8; x++ ) {
      // for each byte(8 bits)
      for (int i = 0; i < 8; i++){
          // pack the bits together
          byte = packBits(line[i + 8*x], i, byte);

      }
      c_out <: byte;
      byte = 0x00;
      //printf( "-%4.1d ", line[ x ] ); //show image values
    }
  }

  //Close PGM image file
  _closeinpgm();
  printf( "DataInStream: Done...\n" );
  return;
}

// Stores the current image
// Send image to each worker
// Also distributes lines to workers sequentially
void distributor(chanend c_in, chanend c_out, chanend fromAcc, chanend toWorker[WORKERS], chanend fromCollector, chanend fromButtonL, out port toLED, chanend fromTimer)
{
  uchar currentImage[IMWD][IMHT/8];
  uchar imageVal;
  int collectorFlag = 0;
  int buttonInput = 0;
  int round = 1;
  int tilted = 0; //we use this to indicate pausing as well
  int pause = 0, noPause = 0;
  int timeElapsed = 0;

  tests();

  //------------------------------------------------------------------------------------------------------------

  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );

  //Starting up and wait for button press of the xCore-200 Explorer
  printf("Waiting for Button press...\n");

  while (buttonInput != 14){ //exits the loop when buttonInput == 14
    fromButtonL :> buttonInput;
  }

  printf("Button Pressed\n");
  toLED <: 4; //green
  printf( "Processing...\n" );
  // Store whatever the image is in a 2D array
  for( int y = 0; y < IMHT; y++ ) {   //go through all lines
    for( int x = 0; x < IMWD/8; x++ ) { //go through each pixel per line
        c_in :> currentImage[y][x];
    }
  }
  printf( "\nProcessing image DONE...\n" );

  while(1){
      [[ordered]]
      select {
         case fromButtonL :> buttonInput:
               if(buttonInput == 13){
                 printf("Current round is: %d \n", round);
                 toLED <: 2;
                 c_out <: 2;
                 pause = 1;
                 for(int y = 0; y<IMHT; y++){
                   for(int x = 0; x<IMWD/8; x++){
                       for(int z = 0; z<8; z++){
                           c_out <: unpackBits(currentImage[y][x], z) ;
                       }
                   }
                 }
                printf("\n Image has been exported %d \n", round);
                toLED <: 0;
                pause = 0;
               }
               else break;
             break;
//---------------------------------------------------------------------------

         case fromAcc :> tilted:
             if (tilted == 1){
                 pause = 1;

                 if (round == 1){
                     noPause = 1;
                 }
                 toLED <: 8; //red

                 if(noPause == 1){
                   printf("Board Tilted... \n");
                   printf("-------------STATUS REPORT-------------\n");
                   printf("Rounds completed: %d\n", round);
                   printf("Live cells: %d\n", totalLiveCells(currentImage));
                   printf("Time elapsed: %d milliseconds\n", timeElapsed);
                   printf("---------------------------------------\n");
                 }

                 while (pause) {
                     fromAcc <: 5;
                     break;
                 }
                noPause++;
             }
             else if (tilted == 0){
                 toLED <: 0;
                 pause = 0;
                 noPause = 0;
             }
             break;
//---------------------------------------------------------------------------------

          case fromCollector :> collectorFlag:
              // flashing LED
              toLED <: round % 2;

              fromTimer <: 1; //telling getTimer() to start calculating a time

              if (collectorFlag == 2) {
                  // recieve current image
                  for(int y = 0; y<IMHT; y++){
                      for(int x = 0; x<IMWD/8; x++){
                          fromCollector :> imageVal;
                          currentImage[y][x] = imageVal;
                      }
                  }
               }
//--------------------------------------------------------------------------------------

              else if (collectorFlag == 3){
                  round++;
                  //--------------------------------------------------------------------
                  // to do the pausing
                      if (pause == 1){ //paused
                          // add worker number global here
                          for(int i=0; i<WORKERS; i++){
                              toWorker[i] <: 8;
                          }
                      }

                      if (pause == 0){ //resumed
                          for(int i=0; i<WORKERS; i++){
                              toWorker[i] <: 9;
                          }
                      }

                  //----------------------------------------------------------------------
                  // split image and send to each worker
                  for (int i=0; i<WORKERS; i++){
                        // number of rows
                        for( int y = 0; y < IMHT/WORKERS; y++ ) {   //go through all lines
                            // elements in each row
                            for( int x = 0; x < IMWD/8; x++ ) { //go through each pixel per line
                                toWorker[i] <: currentImage[y + i*(IMHT/WORKERS)][x];
                            }
                        }

                        // send the two extra lines
                        for( int z = 0; z < IMWD/8; z++ ){
                            // prev workers' line
                            if ((i-1) == -1){
                              toWorker[i] <: currentImage[IMHT-1][z];
                            } else {
                              toWorker[i] <: currentImage[(IMHT/WORKERS-1)+(i-1)*(IMHT/WORKERS)][z];
                            }
                        }
                        for( int a = 0; a < IMWD/8; a++ ){
                            // next workers' line
                            if ((i+1) == WORKERS ){
                                toWorker[i] <: currentImage[0][a];
                            } else {
                                toWorker[i] <: currentImage[(i+1)*(IMHT/WORKERS)][a];
                            }
                        }
                  }
                  fromCollector <: 2;
                  fromAcc <: -5; //sending any value to say that its time to check for a tilt
              }

              fromTimer <: 3; //telling timer to send the time elapsed in seconds
              fromTimer :> timeElapsed;
              break;

      } //end of select
  } //end of while loop
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in)
{
  int res;
  int sig;
  uchar line[ IMWD ];

  //Open PGM file
  while (1){
      c_in :> sig;
      printf( "DataOutStream: Start...\n" );
              res = _openoutpgm( outfname, IMWD, IMHT );
              if( res ) {
              printf( "DataOutStream: Error opening %s\n.", outfname );
              return;
              }
              //Compile each line of the image and write the image line-by-line
              for( int y = 0; y < IMHT; y++ ) {
              for( int x = 0; x < IMWD; x++ ) {
                c_in :> line[ x ];
                if (line[x] == 0x01){
                    line[x] = 0xFF;
                }
                 //printf( "-%4.1d ", line[ x ] ); //show image values
              }
              _writeoutline( line, IMWD );
              //printf( "\n");
              // printf( " DataOutStream: Line written...\n" );
              }
              printf("all lines written");

              //Close the PGM image
              _closeoutpgm();
      printf( "\nDataOutStream: Done...\n" );
  }
  return;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// Initialise and  read orientation, send first tilt event to channel
//
/////////////////////////////////////////////////////////////////////////////////////////
void orientation( client interface i2c_master_if i2c, chanend toDist) {
  i2c_regop_res_t result;
  char status_data = 0;
  int tilted = 0;
  int dist_signal = 0;

  // Configure FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }
  
  // Enable FXOS8700EQ
  result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
  if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
  }

  //Probe the orientation x-axis forever
  while (1) {
    //check until new orientation data is available
    do {
      status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
    } while (!status_data & 0x08);

    //get new x-axis tilt value
    int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

    //send signal to distributor after first tilt
    if (!tilted) {
      if (x>30) {
        tilted = 1;
      }
    }
    // return something to dist to make it continue
    else {
        if (x < 5){
            tilted = 0;
        }
    }
    select{
        case toDist :> dist_signal:
            toDist <: tilted;
            break;
        break;
    }
  } //end of while loop
}



/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
int main(void) {

i2c_master_if i2c[1];  //interface to orientation
chan c_inIO, c_outIO, accToD;
chan workerChans[WORKERS];
chan collect[WORKERS];
chan collectorToD;
chan buttonToD;
chan timerToD;

par {
    on tile[0]: calcTime(timerToD);
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0], accToD);        //client thread reading orientation data
    on tile[0]: buttonListener(buttons, buttonToD);
    on tile[0]: DataInStream("test.pgm", c_inIO);          //thread to read in a PGM image
    on tile[0]: DataOutStream("testout.pgm", c_outIO);       //thread to write out a PGM image
    on tile[0]: distributor(c_inIO, c_outIO, accToD, workerChans, collectorToD, buttonToD, leds, timerToD); //thread to coordinate work on image
    on tile[0]: collector(collect, collectorToD);

    par{
        on tile[0]: worker(collect[0], workerChans[0]);
        on tile[1]: worker(collect[1], workerChans[1]);
        on tile[1]: worker(collect[2], workerChans[2]);
        on tile[1]: worker(collect[3], workerChans[3]);
        on tile[1]: worker(collect[4], workerChans[4]);
        on tile[1]: worker(collect[5], workerChans[5]);
        on tile[1]: worker(collect[6], workerChans[6]);
        on tile[1]: worker(collect[7], workerChans[7]);
    }
  }

  return 0;
}
