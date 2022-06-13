
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


void gen_imap(void)
{
    uint32_t offset = 0;
    uint32_t data;
    int8_t   cnt = 0;

    for(int i=0; i<(MAP_SIZE*MAP_SIZE); i++) {
      for(int j=0; j<(IN_CH/4); j++) {
        for(int k=0; k<4; k++) {
          data = (data << 8) + cnt;
          cnt++;
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
    int8_t   cnt = 0;

    for(int m=0; m<OUT_CH; m++) {
      for(int i=0; i<(3*3); i++) {
        for(int j=0; j<(IN_CH/4); j++) {
          for(int k=0; k<4; k++) {
            data = (data << 8) + cnt;
            cnt++;
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
    int8_t   cnt = 0;

    for(int m=0; m<OUT_CH; m++) {
        for(int j=0; j<(IN_CH/4); j++) {
          for(int k=0; k<4; k++) {
            data = (data << 8) + cnt;
            cnt++;
          }
          SRAM_WRITE32((W1_OFFSET+offset), data);
          offset+=4;
        }
    }
}


int main(void)
{
    /*srand(__get_rv_cycle()  | __get_rv_instret() | __RV_CSR_READ(CSR_MCYCLE));*/
    /*uint32_t rval = rand();*/

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

    return 0;
}

