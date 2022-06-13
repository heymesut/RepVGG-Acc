// See LICENSE for license details.
#ifndef _HBIRDV2_ACC_CFG_H
#define _HBIRDV2_ACC_CFG_H

#ifdef __cplusplus
 extern "C" {
#endif

int32_t acc_config(ACC_CFG_TypeDef *cfg, uint32_t imap_addr, uint32_t w3_addr, uint32_t w1_addr, uint32_t omap_addr, uint32_t map_size, uint32_t in_ch, uint32_t out_ch);
int32_t acc_start(ACC_CFG_TypeDef *cfg);
int32_t check_acc_status(ACC_CFG_TypeDef *cfg);

#ifdef __cplusplus
}
#endif
#endif /* _HBIRDV2_ACC_CFG_H */
