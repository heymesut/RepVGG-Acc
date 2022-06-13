#include "hbirdv2.h"
#include "hbirdv2_acc_cfg.h"

int32_t acc_config(ACC_CFG_TypeDef *cfg, uint32_t imap_addr, uint32_t w3_addr, uint32_t w1_addr, uint32_t omap_addr, uint32_t map_size, uint32_t in_ch, uint32_t out_ch)
{
    if (__RARELY(cfg == NULL)) {
        return -1;
    }
    cfg->IMAP_ADDR = imap_addr;
    cfg->W3_ADDR   = w3_addr;
    cfg->W1_ADDR   = w1_addr;
    cfg->OMAP_ADDR = omap_addr;
    cfg->MAP_SIZE  = map_size;
    cfg->IN_CH     = in_ch;
    cfg->OUT_CH    = out_ch;

    return 0;
}

int32_t acc_start(ACC_CFG_TypeDef *cfg)
{
    if (__RARELY(cfg == NULL)) {
        return -1;
    }
    cfg->CONTROL = 0x1;

    return 0;
}

int32_t check_acc_status(ACC_CFG_TypeDef *cfg)
{
    if (__RARELY(cfg == NULL)) {
        return -1;
    }
    int32_t status = cfg->STATUS;
    
    if(status) {
    	cfg->STATUS = 0x0;
    }

    return status;
}








