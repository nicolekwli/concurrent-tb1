// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo code)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>
#include "pgmIO.h"
//#include "i2c.h"
#include "../lib_i2c/api/i2c.h"

#define  IMHT 16                  //image height
#define  IMWD 16                  //image width

typedef unsigned char uchar;      //using uchar as shorthand

port p_scl = XS1_PORT_1E;         //interface ports to orientation
port p_sda = XS1_PORT_1F;

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

//Function Prototypes cos thats how C works
int noOfLiveNeighbours(char image[16][16], int i, int j);
int gameOfLifeLogic(char image[16][16], int i, int j);

/*
 * NOTES TO NICOLE:
 * 1.OMG OMG OMG OMG !!!!!!! DO WE NEED A CHANNEL FOR A WORKER TO PASS STUFF TO ITSELF?????? !!!!!!!!!11!!!!!!!!!!!!
 * 2.I just realized ive been creating all the arrays and EVERYTHING with 16x16, like hard coded
 *   so we can either change stuff now to accept all sizes or we can do that later?
 *   i guess it wont be that hard to change later??
 * 3.SO ive created many functions and just done stuff that makes sense to me right now
 *   itll all probably change but like ye
 * 4. ive tried to comment as much as i can what i was thinking when i typed that code
 *      hopefully its all understandable
 * 5. this probably wont build because its not really proper code so
 */


/////////////////////////////////////////////////////////////////////////////////////////
//
// The Logic of the Game of Life Game Thing
//
/////////////////////////////////////////////////////////////////////////////////////////
int gameOfLifeLogic(char image[16][16], int i, int j) {
    // just fyi for me: it is array[row][[column]]

   // for (int i=0; i<16; i++) {
       // for (int j=0; j<16; j++){

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
   // } inner for
   // } outer for
    //should return something here
    return 0; //this im not sure about
}

// NEED TO IMPLEMENT SIDE OF BOARD - i think what ive done makes sense?
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
 /* ----------- */
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

//doesnt actually get the next line tho!!!!!!!!!
//idea: maybe send an array of the packed "lines" so that it checks each one and sends the next non empty one
unsigned char sendNextNonEmptyLine(uchar line[16], int i){
    // i so that it starts only from that one cos for workers 2-4 onwards we obv dont need the first non empty line
    //thus make sure worker 1 starts from 0
    for (int n=i; n<16; n++){
        //check if line is empty
        if (line[n] != 0x00) {
          //returns the line that is not empty
          return line[n];

         }
    }

    // has to return something here
}

/*
 * so essentially we need to pack 16 pixels into 1 bit
 * that sounds fun
 * packing 16 bits will give a _ _ _ _ (4 digit) hex number
 * how can we reduce that to one bit, if thats even possible?
 */
unsigned char packBits(char image[16][16], int row_no){
    //function gets the image matrix and row_no is the line no.
    //for example if row_no=8, then we pack the 8th line
    uchar packed_line;

    for(int i=0; i<16; i++){
        for(int j=0; j<16; j++){
            if (row_no == i){
               //pack this shiiiiit right here woo hoo
               //packed_line = stuff;

               break;
            }
        }
    }

    return packed_line;
}

void unpackBits(){

}

/*
 * 1.gets uchar line that is packed from distributor
 * 2.unpacks the line
 * 3.applies the logic
 * 4.send result to data out stream to make it a PGM image file (or do we do this in distributor)
 */
int worker(char image[16][16], int i, int j) {
    //so this is just for one value and it'll change if it was a grid or line-by-line
    int new_val;
    new_val = gameOfLifeLogic(image,i,j);

    return new_val;
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
// Start your implementation by changing this function to implement the game of life
// by farming out parts of the image to worker threads who implement it...
// Currently the function just inverts the image
//
/////////////////////////////////////////////////////////////////////////////////////////
void distributor(chanend c_in, chanend c_out, chanend fromAcc)
{
  uchar val;
 // uchar new_val=0xFF;
  char image[16][16];

  //Starting up and wait for tilting of the xCore-200 Explorer
  printf( "ProcessImage: Start, size = %dx%d\n", IMHT, IMWD );
  printf( "Waiting for Board Tilt...\n" );
  fromAcc :> int value;

  //Read in and do something with your image values..
  //This just inverts every pixel, but you should
  //change the image according to the "Game of Life"
  printf( "Processing...\n" );
  // Store whatever the image is in a 2D array
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
      for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
        c_in :> val;                    //read the pixel value
        image[y][x] = val;              //lol which one is height and which is width gos pls help nicole says it doesnt matter
      }
    }
    printf( "Processing DONE...\n" );
    /* not sure why you did this? shouldnt it be after the while loop anyways? -S
     to make sure stuff work like i don't want to solve error when par is happening i don't even want to think about it */
   //sending the output image (???)
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
      for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
        int new_val = gameOfLifeLogic(image, x, y);

        c_out <: (uchar)new_val;
      }
    }


   /* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    * WHILE LOOP SHOULD DO THIS(ish):
    * 1.create a number of workers
    * 2.send values/lines/grid to workers
    * 3.get result from workers
    * 4.combine result into an new_image
    * 5.send new_image to data out stream to make it a PGM image file (done in worker???)
    */
  while(1){
      uchar all_lines[16]; //this is a list of all packed line
      uchar line; //this is basically the packed line
      //to get the list all_lines[]
      //we cant have a function for this i think because how to pass an array
      //we must avoid pointers at all costs
      /*for(int k=0; k<16; k++){
         line = packBits(image, k);
         all_lines[k] = line;
      }

      // create workers based on number of lines that actually have a live cell
      // not sure how to go about this
      uchar worker1;
      uchar worker2;
      uchar worker3;
      uchar worker4;

      par {

          worker1 = sendNextNonEmptyLine(all_lines, 0);
          worker2 = sendNextNonEmptyLine(all_lines, 4);
          worker3 = sendNextNonEmptyLine(all_lines, 8);
          worker4 = sendNextNonEmptyLine(all_lines, 12);

      }*/

  }

  printf( "\nOne processing round completed...\n" );
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
    }
    _writeoutline( line, IMWD );
    printf( "DataOutStream: Line written...\n" );
  }

  //Close the PGM image
  _closeoutpgm();
  printf( "DataOutStream: Done...\n" );
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

char infname[] = "test.pgm";     //put your input image path here
char outfname[] = "testout.pgm"; //put your output image path here
chan c_inIO, c_outIO, c_control;    //extend your channel definitions here

par {
    i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing orientation data
    orientation(i2c[0],c_control);        //client thread reading orientation data
    DataInStream(infname, c_inIO);          //thread to read in a PGM image
    DataOutStream(outfname, c_outIO);       //thread to write out a PGM image
    distributor(c_inIO, c_outIO, c_control);//thread to coordinate work on image
  }

  return 0;
}
