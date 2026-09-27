// main.c - bare-metal test of the AFDM modulator IP on the ZedBoard.
// Copies one MATLAB test frame into DDR, lets the IP process it, and compares
// every output word with the MATLAB result. Prints over the USB-UART (115200 baud).
//
// Uses the driver Vitis generates for the HLS IP (xafdm_mod_top.h). If a name
// below does not compile, open xparameters.h in the platform and use the base
// address macro it lists for afdm_mod_top_0.
#include <stdio.h>
#include "xil_cache.h"
#include "xparameters.h"
#include "xafdm_mod_top.h"
#include "test_vectors.h"

static uint32_t in_buf[N_SAMPLES]  __attribute__((aligned(64)));
static uint32_t out_buf[N_SAMPLES] __attribute__((aligned(64)));

int main(void) {
    XAfdm_mod_top ip;
    printf("\r\nAFDM modulator on ZedBoard\r\n");

    if (XAfdm_mod_top_Initialize(&ip, XPAR_XAFDM_MOD_TOP_0_BASEADDR) != XST_SUCCESS) {
        printf("IP not found - check the base address in xparameters.h\r\n");
        return 1;
    }

    for (int n = 0; n < N_SAMPLES; n++) { in_buf[n] = TEST_IN[n]; out_buf[n] = 0; }
    Xil_DCacheFlushRange((UINTPTR)in_buf, sizeof(in_buf));     // IP reads DDR, not the cache
    Xil_DCacheFlushRange((UINTPTR)out_buf, sizeof(out_buf));

    XAfdm_mod_top_Set_in(&ip, (u32)(UINTPTR)in_buf);
    XAfdm_mod_top_Set_out(&ip, (u32)(UINTPTR)out_buf);
    XAfdm_mod_top_Start(&ip);
    while (!XAfdm_mod_top_IsDone(&ip)) { }

    Xil_DCacheInvalidateRange((UINTPTR)out_buf, sizeof(out_buf)); // see what the IP wrote
    int bad = 0;
    for (int n = 0; n < N_SAMPLES; n++) {
        if (out_buf[n] != TEST_EXPECTED[n]) {
            if (bad < 5) printf("  sample %d: got 0x%08lX expected 0x%08lX\r\n", n,
                                (unsigned long)out_buf[n], (unsigned long)TEST_EXPECTED[n]);
            bad++;
        }
    }
    printf("%d / %d samples differ -> %s\r\n", bad, N_SAMPLES, bad ? "FAIL" : "PASS (bit-exact with MATLAB)");
    return 0;
}
