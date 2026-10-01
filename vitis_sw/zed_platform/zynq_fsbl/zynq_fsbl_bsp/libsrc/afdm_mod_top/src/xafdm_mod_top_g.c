#include "xafdm_mod_top.h"

XAfdm_mod_top_Config XAfdm_mod_top_ConfigTable[] __attribute__ ((section (".drvcfg_sec"))) = {

	{
		"xlnx,afdm-mod-top-1.0", /* compatible */
		0x40000000 /* reg */
	},
	 {
		 NULL
	}
};