// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
#include "../lib_i2c/api/i2c.h"
//#include <errno.h>

#define  IMHT 16                  //image height
#define  IMWD 16                  //image width

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
uchar gameOfLifeLogic(char image[IMWD][IMHT/8], int i, int k, int j);


uchar packBits(uchar newBit, int position, uchar returnByte){
    uchar val = newBit & 0x01;
    returnByte |= (val << (8-position));
    return returnByte;
}

uchar unpackBits(uchar byte, int pos){
    uchar bit = (byte >> (8-pos)) & 0x01;
    return bit;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// The Logic of the Game of Life Game Thing
//
/////////////////////////////////////////////////////////////////////////////////////////
// row, byte, pos in the byte
uchar gameOfLifeLogic(uchar image[IMWD][IMHT/8], int i, int k, int j) {
    // just fyi for me: it is array[row][[column]]
    int l_neighbours;
    uchar simplifiedImage[3][IMHT/8];
    int row = i;

    // get the three lines
    // this needs to deal with loop arounds
    for (int x = 0; x<3; x++){
        // if row is the first, then need to get the last row for the 3 lines
        if ((row-1) < 0){
            row = IMHT-1;
        }
        // if 3rd row is outof bounds, then get the first row
        else if ((row+1) == IMHT){
            row = 0;
        }
        for (int y=0; y<IMHT/8; y++){

            simplifiedImage[x][y]=image[row][y];


        }
        // if its the last row, row becomes 0 for the next
        if (row == (IMHT-1)){
           row = i;
        }
        row++;
    }
    // save the new image with the rows before and after
    l_neighbours = noOfLiveNeighbours(simplifiedImage, k , j);
    //cell is live
    if (unpackBits(image[i][k],j) == 1) {
        //any live cell with fewer than two live neighbours dies
        if ( l_neighbours<2 ) {
            return (uchar)0x00;
        }
        //any live cell with two or three live neighbours is unaffected
        else if (( l_neighbours==2 )||( l_neighbours==3 )) {
            return unpackBits(image[i][k],j); //or return 1?
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
            return unpackBits(image[i][k],j); //remains the same
        }
    }

    //should return something here
    return 0; //this im not sure about
}

// send image of three rows for that cell to check no. of alive neighbours
// i: byte, j:pos
int noOfLiveNeighbours(uchar image[3][IMHT/8], int i, int j) {
    int live_n =0;

    // the cell will defo be image[1][i]
    int leftBytePos = i;
    int rightBytePos = i;
    // j is the bit pos in the same row
    int right = j+1;
    int left = j-1;

    // if cell is first in byte, then go to previous
    if (left == -1){
        left = 7;
        if (leftBytePos == 0){
            leftBytePos = IMHT/8 -1;
        }
    }
    if (right == 8){
       right = 0;
       if (rightBytePos == IMHT/8-1){
           rightBytePos = 0;
       }
    }
 /* ------------------------------------------ */
    if (unpackBits(image[1][rightBytePos], right)==1) //right side
        live_n++;

    if (unpackBits(image[1][leftBytePos], left)==1) //left side
        live_n++;

    if (unpackBits(image[0][i], j)==1) //top
        live_n++;

    if (unpackBits(image[2][i], j)==1) //bottom
        live_n++;

    if (unpackBits(image[0][rightBytePos], right)==1) //top right
        live_n++;

    if (unpackBits(image[0][leftBytePos], left)==1) //top left
        live_n++;

    if (unpackBits(image[2][rightBytePos], right)==1)  //bottom right
        live_n++;

    if (unpackBits(image[2][leftBytePos], left)==1)  //bottom left
        live_n++;

  // printf("live neighbours %d\n", live_n);
  return live_n;
}

int totalLiveCells(uchar image[IMWD][IMHT/8]){
    int live = 0;
    for (int i=0; i<IMWD; i++) {
        for (int j=0; j<IMHT/8; j++) {
            for (int k=0; k<8; k++)
            if (unpackBits(image[i][j], k)==0xFF)
              live++;
        }
    }
    return live;
}


//can be implemented later i guess
// return true or false indicating whether line should be processed
/*unsigned short getLineToBeProcessed(ushor lines[16]){
    for (int n=0; n<16; n++){
        //check if line is not empty (might want to keep this)
        if (lines[n] != 0x00 ) {
            return lines[n];
        }
        else if (lines[0] == 0x00){
            if ((lines[1] != 0x00)||(lines[15] != 0x00)){
                return lines[0];
            }
        }
        else if (lines[15] == 0x00){
            if ((lines[0] != 0x00)||(lines[14] != 0x00)){
                return lines[15];
            }
        }
        else if (lines[n] == 0x00) {

            if ((lines[n+1] != 0x00)||(lines[n-1] != 0x00)){
                return lines[n];
            }
        }
    }
    return 0x00; // lol what
}*/


// Represents each worker
// Goes through the row instructed by the distributor
// Sends the resulting value of each cell to the collector till each row is done
// And then moves on to next row sent by the distributor
void worker(chanend toCollect, chanend fromDist){
    uchar new_val;
    uchar byte = 0x00;
    int row;
    uchar image[IMWD][IMHT/8]; //shouldnt this be uchar
    int pause = 9;

    while (1){
        // get image
        fromDist :> pause;
        //printf("pause is received");

        if(pause == 9){
            // row
            for( int y = 0; y < IMWD; y++ ) {   //go through all lines
                // element in each row
                for( int x = 0; x < IMHT/8; x++ ) { //go through each pixel per line
                   fromDist :> image[y][x];
                }
              }
            //printf("entire image sent and received\n");
            // get the line to be processed from distributor
            // this was four buy why - it was to go through the four lines assigned to the worker
            // starting from the row number received
            // this makes sure the worker gets the number of lines it will be assigned
            // for each row sent
            for (int  i=0 ; i<IMHT/4 ; i++){
                fromDist :> row;
                // for (int i=0; i<16; i++){
                //check if line is not empty (might want to keep this)
                //if (line[n] != 0x00) {
                /// unpack line and send position of bit to gameOfLifeLogic
                //printf("Row received %d\n", row);
                // performs the logic on each bit in a row
                // for each array in that row
                for(int k = 0; k < IMHT/8; k++){
                    // for each element in that array
                    for (int j=0; j<8; j++){
                        // get the bit needed in the line
                        //shiftLine |= (line >> (15-j));
                        //if ((shiftLine & 0x01) == 1){

                        // row: the row, k: the byte in that row, j: the position of the bit
                        new_val = gameOfLifeLogic(image,row,k,j);
                        //}
                        //else new_val = shiftLine & 0x01;
                        byte = packBits(new_val, j, byte);


                    }
                    toCollect <: byte;
                    //printf("byte is sent to collect\n");
                    byte = 0x00;
                }
                //printf("WORKER IS DONE\n");

            }
                 //}
        }
    }

} //end of worker()

// Collects data each and sends to output image in order
// I'm guessing it should be stored in an image and sent back to distributor for next round for next iteration(add code)
// otherwise we allow the current code to run and output the image
void collector(chanend fromWorker[4], chanend toDistributor){
    uchar val;
    char newImage[IMWD][IMHT/8];
    int rowCount;
    int sig = 0;

    while (1){
        rowCount = 0;
        toDistributor <: 3;
        //printf("to distributor 3 sent \n ");
        // what is this /4 /8 8
        for (int k=0; k<IMHT/4; k++){
            // number of workers
            for (int i=0; i<4; i++){
                // number of bytes for each worker process
                for (int j=0; j<IMHT/8; j++){
                    //for (int count = 0 ; count < 8; count++){
                        fromWorker[i] :> val;
                        newImage[rowCount][j] = val;
                        //printf("collected from worker %d count %d: %u \n", i,count,  val);
                        //printf("- %u", val);
                        //printf("%d", count);
                    //}

                }
                rowCount++;
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
        //printf("Image sent back to dist\n");
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
    printf( "\n" );
  }

  //Close PGM image file
  _closeinpgm();
  printf( "DataInStream: Done...\n" );
  return;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
//          WRITE A PROPER DESCRIPTION HERE
//
// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
//
/////////////////////////////////////////////////////////////////////////////////////////

// Stores the current image
// Send image to each worker
// Also distributes lines to workers sequentially
void distributor(chanend c_in, chanend c_out, chanend fromAcc, chanend toWorker[4], chanend fromCollector, chanend fromButtonL, out port toLED)
{
 // uchar val;
 // uchar new_val=0xFF;
//  uchar image[16][16]; //i have made this variable obsolete muahahaha
  uchar currentImage[IMWD][IMHT/8];
  uchar imageVal;
  int collectorFlag = 0;
  int buttonInput = 0;
  int round = 1;
  int tilted = 0; //we use this to indicate pausing as well
  int pause = 0;

  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );
  //printf( "Waiting for Board Tilt...\n" );
  //fromAcc :> int value;

  //Starting up and wait for button press of the xCore-200 Explorer
  printf("Waiting for Button press...\n");

  while (buttonInput != 14){
    fromButtonL :> buttonInput;
    //exits the loop when buttonInput == 14
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

  /*for (int d=0; d< 16; d++){
      for (int f=0; f< 2; f++){
          printf("line %u", currentImage[d][f]);
      }
      printf("\n");
  }*/


   /*
    * WHILE LOOP SHOULD DO THIS(ish):
    * 1.create a number of workers
    * 2.send values/lines/grid to workers
    * 3.get result from workers
    */

  //FOR PAUSING: put this somewhere appropriate
  // telling the workers that pause is 0
  /*for(int i=0; i<4; i++){
    toWorker[i] <: 0;
  }*/

  while(1){
      /*for (int d=0; d< 16; d++){
            for (int f=0; f< 2; f++){
                printf("line %u", currentImage[d][f]);
            }
            printf("\n");
        }*/

      [[ordered]]
      select {
         case fromButtonL :> buttonInput:
               if(buttonInput == 13){
                 printf("Current round is: %d \n", round);
                 toLED <: 2;
                 // displays the current image
                 for(int y = 0; y<IMHT; y++){
                   for(int x = 0; x<IMWD/8; x++){
                       for(int z = 0; z<8; z++){
                           c_out <: unpackBits(currentImage[y][x], z);
                       }

                   }
                 }
                 toLED <: 0;
               }
               else break;
             break;

         case fromAcc :> tilted:
             if (tilted == 1) {
                 //printf("Board Tilted... \n");

                 pause = 1;
                 toLED <: 8; //red
                 //printf("Paused. \n");


                 printf("------------STATUS REPORT------------\n");
                 printf("Rounds completed: %d\n", round);
                 printf("Live cells: %d\n", totalLiveCells(currentImage));
                 //printf("Time elapsed: %d\n", time);
                 printf("-------------------------------------\n");
                 //delay_milliseconds(200);
                 while (pause) {
                     fromAcc <: 5;
                     break;
                    // toLED <: 8; //red
                 }

             }
             else if (tilted == 0){
                 printf("Unpaused. \n");
                 toLED <: 0;
                 pause = 0;
             }
             break;

          case fromCollector :> collectorFlag:
              //put flashing LED here
              toLED <: ((round)%2);

              if (collectorFlag == 2) {
                  printf("\n Processing round %d... \n", round);
                  // recieve current image
                  for(int y = 0; y<IMHT; y++){
                      for(int x = 0; x<IMWD/8; x++){
                          //printf("recieving image \n");
                          fromCollector :> imageVal;
                          currentImage[y][x] = imageVal;
                      }
                  }
               }
              else if (collectorFlag == 3){
                  //printf("FLAG 3 COLLECTED");
                  // to do the pausing
                      if (pause == 1){ //paused
                          for(int i=0; i<4; i++){
                              toWorker[i] <: 8;
                          }
                      }

                      if (pause == 0){ //resumed
                          for(int i=0; i<4; i++){
                              toWorker[i] <: 9;
                          }
                      }


                  // split image and send to workers
                  // number of rows
                  for( int y = 0; y < IMHT; y++ ) {   //go through all lines
                      // elements in each row
                      for( int x = 0; x < IMWD/8; x++ ) { //go through each pixel per line
                          toWorker[0] <: currentImage[y][x];
                          toWorker[1] <: currentImage[y][x];
                          toWorker[2] <: currentImage[y][x];
                          toWorker[3] <: currentImage[y][x];
                      }
                  }
                  //printf("sending image done \n ");
                  // what does this send? the number of rows
                  for(int k=0; k<IMWD; k++){
                      // send row number of line
                      // toWorker[k%4] <: all_lines[k];
                      //printf("sent line %d to worker %d\n", k, k%4);
                      toWorker[k%4] <: k;
                      //toWorker[k%4] :> val;
                  }
                  fromCollector <: 2;
                  //printf("SIGNAL SENT 2 TO COLLECTOR\n");
                  round++;
                  fromAcc <: -5; //sending any value to say that its time to check for a tilt
              }

              else printf("hi something happens idk \n");

              break;
      }
  } //end of while loop
 // printf( "\nOne processing round completed... \n" );
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in)
{
  int res;
  uchar line[ IMWD ];

  //Open PGM file
  while (1){
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
                 printf( "-%4.1d ", line[ x ] ); //show image values
                //printf("%d", x);
              }
              _writeoutline( line, IMWD );
              //printf("Y IS: %d \n", y);
              printf( "\n");
              //printf( " DataOutStream: Line written...\n" );
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
        //toDist <: 1;
      }
    }
    // return soething to dist to make it continue
    else {
        if (x < 5){
            tilted = 0;
            //toDist <: 0;
        }
    }
    select{
        case toDist :> dist_signal:
            toDist <: tilted;
            break;
        break;
    }


  }
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
int main(void) {

i2c_master_if i2c[1];               //interface to orientation

//char infname[] = "test.pgm";     //put your input image path here
//char outfname[] = "testout.pgm"; //put your output image path here
chan c_inIO, c_outIO, accToD;
chan workerChans[4];
chan collect[4];
chan collectorToD;
chan buttonToD;

par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0], accToD);        //client thread reading orientation data
    on tile[0]: buttonListener(buttons, buttonToD);
    on tile[0]: DataInStream("test.pgm", c_inIO);          //thread to read in a PGM image
    on tile[0]: DataOutStream("testout.pgm", c_outIO);       //thread to write out a PGM image
    on tile[0]: distributor(c_inIO, c_outIO, accToD, workerChans, collectorToD, buttonToD, leds); //thread to coordinate work on image
    on tile[0]: collector(collect, collectorToD);

    // for loop to create workers
    /*par (int i = 0; i < 4 ; i++) {
        on tile[0]: worker(collect[i], workerChans[i]);
    }*/
    par{
        on tile[1]: worker(collect[0], workerChans[0]);
        on tile[1]: worker(collect[1], workerChans[1]);
        on tile[1]: worker(collect[2], workerChans[2]);
        on tile[1]: worker(collect[3], workerChans[3]);
    }
  }

// SW1 is 14 and SW2 is 13

  return 0;
}
