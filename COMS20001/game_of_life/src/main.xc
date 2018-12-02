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
int noOfLiveNeighbours(char image[16][16], int i, int j);
int gameOfLifeLogic(char image[16][16], int i, int j);


/////////////////////////////////////////////////////////////////////////////////////////
//
// The Logic of the Game of Life Game Thing
//
/////////////////////////////////////////////////////////////////////////////////////////
int gameOfLifeLogic(char image[16][16], int i, int j) {
    // just fyi for me: it is array[row][[column]]

    int l_neighbours;
    l_neighbours = noOfLiveNeighbours(image, i , j);
    //cell is live
    if (image[i][j] == 0xFF) {
        //any live cell with fewer than two live neighbours dies
        if ( l_neighbours<2 ) {
            return 0;
        }
        //any live cell with two or three live neighbours is unaffected
        else if (( l_neighbours==2 )||( l_neighbours==3 )) {
            return image[i][j]; //or return 1?
        }
        //any live cell with more than three live neighbours dies
        else if ( l_neighbours>3 ) {
            return 0;
        }
    }
    //cells are dead
    else if (image[i][j] == 0) {
        //any dead cell with exactly three live neighbours becomes alive
        if ( l_neighbours==3 ) {
            return (uchar)0xFF;
        }
        else {
            return image[i][j]; //remains the same
        }
    }

    //should return something here
    return 0; //this im not sure about
}

int noOfLiveNeighbours(char image[16][16], int i, int j) {
    int live_n =0;

    int right = j+1;
    int left = j-1;
    int top = i-1;
    int bottom = i+1;

    if (top == -1){
        top = 15;
    }
    if (bottom == 16){
        bottom = 0;
    }
    if (left == -1){
        left = 15;
    }
    if (right == 16){
       right = 0;
    }
 /* ------------------------------------------ */
    if (image[i][right]==0xFF) //right side
        live_n++;

    if (image[i][left]==0xFF) //left side
        live_n++;

    if (image[top][j]==0xFF) //top
        live_n++;

    if (image[bottom][j]==0xFF) //bottom
        live_n++;

    if (image[top][right]==0xFF) //top right
        live_n++;

    if (image[top][left]==0xFF) //top left
        live_n++;

    if (image[bottom][right]==0xFF)  //bottom right
        live_n++;

    if (image[bottom][left]==0xFF)  //bottom left
        live_n++;

  // printf("live neighbours %d\n", live_n);
  return live_n;
}


unsigned short packBits(uchar image[16][16], int row_no){
    //function gets the image matrix and row_no is the line no.
    //for example if row_no=8, then we pack the 8th line
    ushor packed_line = 0;

    //int line;
    ushor val;

    // printf("packing bits...");
    for(int j=0; j<16; j++){
        val = (image[row_no][j]) & 0x01;
        //printf("a val: %u\n", val);
        //printf("a packedline before: %x\n", packed_line);

        if (val != 0){
            packed_line |= (1 << (15-j));
        }

        // printf("a packedline: %u\n", packed_line);
    }
    //printf("a line: %u\n", packed_line);
    return packed_line;
}

void unpackBits(ushor line){

}

//can be implemented later i guess
// return true or false indicating whether line hsould be processed
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
    return 0x00;
}*/


// Represents each worker
// Goes through the row instructed by the distributor
// Sends the resulting value of each cell to the collector till each row is done
// And then moves on to next row sent by the distributor
void worker(chanend toCollect, chanend fromDist){
    //ushor shiftLine = 0;
    uchar new_val;
    // ushor line[16];
    ushor line;
    int row;

    char image[16][16];
    // get image
    for( int y = 0; y < 16; y++ ) {   //go through all lines
        for( int x = 0; x < 16; x++ ) { //go through each pixel per line
           fromDist :> image[y][x];
        }
      }
    //printf("entire image sent and received\n");

    while (1){
        // get the line to be processed from distributor
            //printf("line received\n");
            fromDist :> row;
            //printf("row received\n");
            // for (int i=0; i<16; i++){
                //check if line is not empty (might want to keep this)
                //if (line[n] != 0x00) {
                  /// unpack line and send position of bit to gameOfLifeLogic
                  for (int j=0; j<16; j++){
                    // get the bit needed in the line
                    //shiftLine |= (line >> (15-j));
                    //if ((shiftLine & 0x01) == 1){
                    new_val = gameOfLifeLogic(image,row,j);
                    //}
                    //else new_val = shiftLine & 0x01;
                    // c_out <: new_val;
                    toCollect <: new_val;
                  }
                 //}
    }
}

// Collects data each and sends to output image in order
// I'm guessing it should be stored in an image and sent back to distributor for next round for next iteration(add code)
// otherwise we allow the current code to run and output the image
void collector(chanend fromWorker[4], chanend toDistributor){
    uchar val;

   // uchar currentImage[16][16];
    char newImage[16][16];

    int rowCount = 0;

    while (1){
        toDistributor <: 3;
        for (int i=0; i<4; i++){
            for (int count = 0 ; count < 16; count++){
                fromWorker[i] :> val;
                newImage[rowCount][count] = val;
                //printf("collected from worker %d %u \n", i, val);
                //printf("- %u", val);
                // toDistributor <: val;
                //c_out <: val;
                //printf("%d", count);
            }
            rowCount++;
        }

        // After collecting we send to the distributor
        toDistributor <: 2;
        for(int y = 0; y<16; y++){
            for(int x = 0; x<16; x++){
                toDistributor <: newImage[y][x];
            }
        }
    }

    printf("end of collector \n ");

}

void sendToDataOutStream(uchar currentImage[16][16], chanend c_out){
   // c_out <: val;
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
    for( int x = 0; x < IMWD; x++ ) {
      c_out <: line[ x ];
      printf( "-%4.1d ", line[ x ] ); //show image values
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
void distributor(chanend c_in, chanend c_out, chanend fromAcc, chanend toWorker[4], chanend fromCollector, in port fromButton)
{
 // uchar val;
 // uchar new_val=0xFF;
  uchar image[16][16]; //i have made this variable obsolete muahahaha
  uchar currentImage[16][16];
  uchar imageVal;
  int collectorFlag = 0;
  int buttonInput = 0;
  int round = 1;

  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );
  //printf( "Waiting for Board Tilt...\n" );
  //fromAcc :> int value;

  //Starting up and wait for button press of the xCore-200 Explorer
  printf("Waiting for Button press...\n");
  //SW1 - this needs to be changed
  while (buttonInput != 14){
    fromButton :> buttonInput;
  }
  printf("Button Pressed\n");

  printf( "Processing...\n" );
  // Store whatever the image is in a 2D array
  for( int y = 0; y < IMHT; y++ ) {   //go through all lines
    for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
      // c_in :> val;                    //read the pixel value
      // image[y][x] = val;              //[height][width]
      //c_in :> image[y][x];
        c_in :> currentImage[y][x];
      //currentImage[y][x] = image[y][x];     //initializing the curre
    }
  }
  printf( "\nProcessing image DONE...\n" );

   /*
    * WHILE LOOP SHOULD DO THIS(ish):
    * 1.create a number of workers
    * 2.send values/lines/grid to workers
    * 3.get result from workers
    */
  while(1){
      //ushor all_lines[16]; //this is a list of all packed line
      //ushor linesToBeProcessed[16];
      //ushor line; //this is basically the packed line

      //to get the list all_lines[]
      /*for(int k=0; k<16; k++){
         line = packBits(image, k);
         all_lines[k] = line;
      }*/

      //to remove empty lines with all 0s
      //this is messy; to be fixed at some point
      /*for(int l=0; l<16; l++){
        linesToBeProcessed[l] = getLineToBeProcessed(all_lines);
      }
      for(int a=0; a<16; a++){
          printf(" \n lines to be processed %d: %u\n", a, linesToBeProcessed[a]);
      }*/

      select {
         /* case fromButton :> buttonInput:
              fromButton :> buttonInput
              if(buttonInput == 13){
                 printf("Current round is: %d\n");
                 //leds <: 2;
                 //sendToDataOutStream(currentImage, c_out);
                 // displays the current image
                 for(int y = 0; y<16; y++){
                   for(int x = 0; x<16; x++){
                       c_out <: currentImage[y][x];
                   }
                 }
              }
              else printf("Incorrect button");
              break;
        */
          case fromCollector :> collectorFlag:
              if (collectorFlag == 2) {
                  printf("\n Processing round %d... \n", round);

                  //if (round > 1) {
                      // recieve current image
                        for(int y = 0; y<16; y++){
                            for(int x = 0; x<16; x++){
                                printf("recieving image \n");
                                fromCollector :> imageVal;
                                currentImage[y][x] = imageVal;
                            }
                        }
                        printf("image recieved \n ");
                  //}
              }
                else if (collectorFlag = 3){
                    // split image and send to workers
                      // MODIFY: should send image as only the lines the workers should deal with
                      // should also send an extra top and bottom row
                      for( int y = 0; y < 16; y++ ) {   //go through all lines
                          for( int x = 0; x < 16; x++ ) { //go through each pixel per line
                              toWorker[0] <: currentImage[y][x];
                              toWorker[1] <: currentImage[y][x];
                              toWorker[2] <: currentImage[y][x];
                              toWorker[3] <: currentImage[y][x];
                          }
                      }
                      printf("sending image done \n ");
                      // send lines according to toWorker[]
                      for(int k=0; k<16; k++){
                          printf("allocating \n ");
                          // send row number of line
                          // printf("line sent to %d \n", k);
                          // toWorker[k%4] <: all_lines[k];
                          // printf("sent line %d to worker %d\n", k, k%4);
                          toWorker[k%4] <: k;
                          //toWorker[k%4] :> val;
                          //c_out <: val;
                      }
                      printf("allocating lines to workers done \n");
                }
                  //round++;
              else printf("hi something happens idk \n");

              break;
      }


      //worker(image, linesToBeProcessed, 0, c_out);

      printf("OUTPUT AFTER ROUND: \n");
      for( int y = 0; y < 16; y++ ) {   //go through all lines
          for( int x = 0; x < 16; x++ ) { //go through each pixel per line
             c_out <: currentImage[y][x];
          }
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
        tilted = 1 - tilted;
        toDist <: 1;
      }
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
chan c_inIO, c_outIO, c_control;    //extend your channel definitions here
chan workerChans[4];
chan collect[4];
chan ColtoDist; //change this nameeeeeeeeee

par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    on tile[0]: orientation(i2c[0],c_control);        //client thread reading orientation data
    on tile[1]: DataInStream("test.pgm", c_inIO);          //thread to read in a PGM image
    on tile[1]: DataOutStream("testout.pgm", c_outIO);       //thread to write out a PGM image
    on tile[0]: distributor(c_inIO, c_outIO, c_control, workerChans, ColtoDist, buttons); //thread to coordinate work on image
    on tile[0]: collector(collect, ColtoDist);
    // for loop to create workers
    par (int i = 0; i < 4 ; i++) {
        on tile[0]: worker(collect[i], workerChans[i]);
    }
  }

  return 0;
}
