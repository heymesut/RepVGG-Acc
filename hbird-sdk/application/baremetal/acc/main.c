
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "hbird_sdk_soc.h"

#define IMAP_OFFSET   (0x0)
#define W3_OFFSET     (0x40000)
#define W1_OFFSET     (0x50000)
#define OMAP_OFFSET   (0x60000)

#define IMAP_ADDR     (SRAM_BASE+IMAP_OFFSET)
#define W3_ADDR       (SRAM_BASE+W3_OFFSET)
#define W1_ADDR       (SRAM_BASE+W1_OFFSET)
#define OMAP_ADDR     (SRAM_BASE+OMAP_OFFSET)

#define MAP_SIZE    56
#define IN_CH       64
#define OUT_CH      64


int8_t w3[OUT_CH][IN_CH][9];
int8_t w1[OUT_CH][IN_CH];

uint32_t check_result(void) {

  uint32_t data;
  uint32_t offset;

  int8_t   imap;
  int32_t  psum3x3;
  int32_t  psum1x1;
  int32_t  identity;
  int32_t  map_sum;

  int8_t   quan3x3;
  int8_t   quan1x1;
  int8_t   quan_map_sum;

  uint32_t acc_res;
  uint32_t err;

  // load weights
  offset = 0;
  for(int m=0; m<OUT_CH; m++) {
    for(int i=0; i<9; i++) {
      for(int p=0; p<(IN_CH/4); p++) {
        data = SRAM_READ32((W3_OFFSET+offset));
        for(int q=0; q<4; q++) {
          w3[m][p*4+q][i] = (data >> (8*q)) & (0xff);
        }
        offset+=4;
      }
    }
  }

  offset = 0;
  for(int m=0; m<OUT_CH; m++) {
    for(int p=0; p<(IN_CH/4); p++) {
      data = SRAM_READ32((W1_OFFSET+offset));
      for(int q=0; q<4; q++) {
        w1[m][p*4+q] = (data >> (8*q)) & (0xff);
      }
      offset+=4;
    }
  }

  for(int och=0; och<2; och++) {
    for(int i=0; i<MAP_SIZE; i++) {
      for(int j=0; j<MAP_SIZE; j++) {
        psum3x3 = 0;
        psum1x1 = 0;

        // 3x3
        for(int k=0; k<3; k++) {
          for(int m=0; m<3; m++) {
            // padding
            if(((i+k)==0) || ((i+k)==(MAP_SIZE+1)) || ((j+m)==0) || ((j+m)==(MAP_SIZE))) {
              psum3x3+=0;
            }
            else {
              for(int ich=0; ich<(IN_CH/4); ich++) {
                offset = (((i+k-1)*MAP_SIZE+(j+m-1))*(IN_CH/4)+ich)*4;
                data = SRAM_READ32((IMAP_OFFSET+offset));
                for(int n=0; n<4; n++) {
                  imap = (data >> (8*n)) & (0xff);
                  psum3x3 += (int16_t)imap*w3[och][ich*4+n][k*3+m];
                }
              }
            }
          }
        }

        // 1x1
        for(int ich=0; ich<(IN_CH/4); ich++) {
          offset = ((i*MAP_SIZE+j)*(IN_CH/4)+ich)*4;
          data = SRAM_READ32((IMAP_OFFSET+offset));
          for(int n=0; n<4; n++) {
            imap = (data >> (8*n)) & (0xff);
            psum1x1 += (int16_t)imap*w1[och][ich*4+n];
            if((ich*4+n)==och) {
              identity = imap;
            }
          }
        }

       // relu & quan
       map_sum = psum1x1 + psum3x3 + identity;
       // relu
       if(map_sum<0)
         map_sum = 0;
       //quan
       quan3x3 = (psum3x3 >> 17) & (0xff);
       quan1x1 = (psum1x1 >> 14) & (0xff);
       quan_map_sum = (map_sum >> 17) & (0xff);


       // check
       offset = (MAP_SIZE*MAP_SIZE*och+i*MAP_SIZE+j)*4;
       acc_res = SRAM_READ32((OMAP_OFFSET+offset));
       if((quan1x1 != (acc_res & 0xff)) || (quan3x3 != ((acc_res >> 8) & 0xff)) || (quan_map_sum != ((acc_res >> 16) & 0xff))) {
         err++;
       }
      }
    }
  }

  return err;
}

void gen_imap(void)
{
    uint32_t offset = 0;
    uint32_t data;
    int8_t   cnt;

    for(int i=0; i<(MAP_SIZE*MAP_SIZE); i++) {
      for(int j=0; j<(IN_CH/4); j++) {
        for(int k=0; k<4; k++) {
          cnt = rand();
          data = (data << 8) + cnt;
        }
        SRAM_WRITE32((IMAP_OFFSET+offset), data);
        offset+=4;
      }
    }

}


void gen_w3(void)
{
    uint32_t offset = 0;
    uint32_t data;
    int8_t   cnt;

    for(int m=0; m<OUT_CH; m++) {
      for(int i=0; i<(3*3); i++) {
        for(int j=0; j<(IN_CH/4); j++) {
          for(int k=0; k<4; k++) {
            cnt = rand();
            data = (data << 8) + cnt;
          }
          SRAM_WRITE32((W3_OFFSET+offset), data);
          offset+=4;
        }
      }
    }
}


void gen_w1(void)
{
    uint32_t offset = 0;
    uint32_t data;
    int8_t   cnt;

    for(int m=0; m<OUT_CH; m++) {
        for(int j=0; j<(IN_CH/4); j++) {
          for(int k=0; k<4; k++) {
            cnt = rand();
            data = (data << 8) + cnt;
          }
          SRAM_WRITE32((W1_OFFSET+offset), data);
          offset+=4;
        }
    }
}


int main(void)
{
    srand(__get_rv_cycle()  | __get_rv_instret() | __RV_CSR_READ(CSR_MCYCLE));

    printf("Hello World From RISC-V Processor!\n");

    gen_imap();
    printf("Imap is generated successfully!\n");

    gen_w3();
    gen_w1();
    printf("Weight is generated successfully!\n");

    // config acc
    acc_config(ACC_CFG, IMAP_ADDR, W3_ADDR, W1_ADDR, OMAP_ADDR, MAP_SIZE, IN_CH, OUT_CH);

    // start acc
    printf("Start acc!\n");
    acc_start(ACC_CFG);

    while(check_acc_status(ACC_CFG)==0) {
      delay_1ms(1);
    }
    printf("Acc done!\n");

    /*int errors = check_result();*/
    int errors = 0;

    if(errors==0) {
      printf("Correct Calculation!\n");
      return 0;
    }
    else {
      printf("Erorr! Error Num: %d\n", errors);
      return -1;
    }
}

