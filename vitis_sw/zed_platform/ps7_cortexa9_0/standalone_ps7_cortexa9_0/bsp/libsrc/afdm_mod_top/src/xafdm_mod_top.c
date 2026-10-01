// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2025.2 (64-bit)
// Tool Version Limit: 2025.11
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
/***************************** Include Files *********************************/
#include "xafdm_mod_top.h"

/************************** Function Implementation *************************/
#ifndef __linux__
int XAfdm_mod_top_CfgInitialize(XAfdm_mod_top *InstancePtr, XAfdm_mod_top_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->Control_BaseAddress = ConfigPtr->Control_BaseAddress;
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}
#endif

void XAfdm_mod_top_Start(XAfdm_mod_top *InstancePtr) {
    u32 Data;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL) & 0x80;
    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL, Data | 0x01);
}

u32 XAfdm_mod_top_IsDone(XAfdm_mod_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL);
    return (Data >> 1) & 0x1;
}

u32 XAfdm_mod_top_IsIdle(XAfdm_mod_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL);
    return (Data >> 2) & 0x1;
}

u32 XAfdm_mod_top_IsReady(XAfdm_mod_top *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL);
    // check ap_start to see if the pcore is ready for next input
    return !(Data & 0x1);
}

void XAfdm_mod_top_EnableAutoRestart(XAfdm_mod_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL, 0x80);
}

void XAfdm_mod_top_DisableAutoRestart(XAfdm_mod_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_AP_CTRL, 0);
}

void XAfdm_mod_top_Set_in_r(XAfdm_mod_top *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IN_R_DATA, (u32)(Data));
    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IN_R_DATA + 4, (u32)(Data >> 32));
}

u64 XAfdm_mod_top_Get_in_r(XAfdm_mod_top *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IN_R_DATA);
    Data += (u64)XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IN_R_DATA + 4) << 32;
    return Data;
}

void XAfdm_mod_top_Set_out_r(XAfdm_mod_top *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_OUT_R_DATA, (u32)(Data));
    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_OUT_R_DATA + 4, (u32)(Data >> 32));
}

u64 XAfdm_mod_top_Get_out_r(XAfdm_mod_top *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_OUT_R_DATA);
    Data += (u64)XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_OUT_R_DATA + 4) << 32;
    return Data;
}

void XAfdm_mod_top_InterruptGlobalEnable(XAfdm_mod_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_GIE, 1);
}

void XAfdm_mod_top_InterruptGlobalDisable(XAfdm_mod_top *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_GIE, 0);
}

void XAfdm_mod_top_InterruptEnable(XAfdm_mod_top *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IER);
    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IER, Register | Mask);
}

void XAfdm_mod_top_InterruptDisable(XAfdm_mod_top *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IER);
    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IER, Register & (~Mask));
}

void XAfdm_mod_top_InterruptClear(XAfdm_mod_top *InstancePtr, u32 Mask) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XAfdm_mod_top_WriteReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_ISR, Mask);
}

u32 XAfdm_mod_top_InterruptGetEnabled(XAfdm_mod_top *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_IER);
}

u32 XAfdm_mod_top_InterruptGetStatus(XAfdm_mod_top *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XAfdm_mod_top_ReadReg(InstancePtr->Control_BaseAddress, XAFDM_MOD_TOP_CONTROL_ADDR_ISR);
}

