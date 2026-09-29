// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2025.2 (64-bit)
// Tool Version Limit: 2025.11
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#ifdef SDT
#include "xparameters.h"
#endif
#include "xafdm_mod_top.h"

extern XAfdm_mod_top_Config XAfdm_mod_top_ConfigTable[];

#ifdef SDT
XAfdm_mod_top_Config *XAfdm_mod_top_LookupConfig(UINTPTR BaseAddress) {
	XAfdm_mod_top_Config *ConfigPtr = NULL;

	int Index;

	for (Index = (u32)0x0; XAfdm_mod_top_ConfigTable[Index].Name != NULL; Index++) {
		if (!BaseAddress || XAfdm_mod_top_ConfigTable[Index].Control_BaseAddress == BaseAddress) {
			ConfigPtr = &XAfdm_mod_top_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XAfdm_mod_top_Initialize(XAfdm_mod_top *InstancePtr, UINTPTR BaseAddress) {
	XAfdm_mod_top_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XAfdm_mod_top_LookupConfig(BaseAddress);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XAfdm_mod_top_CfgInitialize(InstancePtr, ConfigPtr);
}
#else
XAfdm_mod_top_Config *XAfdm_mod_top_LookupConfig(u16 DeviceId) {
	XAfdm_mod_top_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XAFDM_MOD_TOP_NUM_INSTANCES; Index++) {
		if (XAfdm_mod_top_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XAfdm_mod_top_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XAfdm_mod_top_Initialize(XAfdm_mod_top *InstancePtr, u16 DeviceId) {
	XAfdm_mod_top_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XAfdm_mod_top_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XAfdm_mod_top_CfgInitialize(InstancePtr, ConfigPtr);
}
#endif

#endif

