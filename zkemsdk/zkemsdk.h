/*
 * NOTE:
 * This header was reconstructed from:
 *
 *   - zkemsdk.dll exports
 *   - zkemkeeper.dll documentation
 *
 * Some signatures, especially SSR_Z_GetLog(),
 * may require verification against real hardware.
 */

#ifndef ZKEMSDK_H
#define ZKEMSDK_H

#ifdef _WIN32
#define ZKEM_CALL __stdcall
#else
#define ZKEM_CALL
#endif

typedef int ZK_BOOL;

/*
 * Connection
 */

ZK_BOOL ZKEM_CALL Z_Connect_NET(
    const char *ip,
    int port
);

void ZKEM_CALL Z_Close(void);

/*
 * Device control
 */

ZK_BOOL ZKEM_CALL Z_EnableDevice(
    int machine_number,
    ZK_BOOL enabled
);

/*
 * Attendance logs
 */

ZK_BOOL ZKEM_CALL Z_ReadLog(
    int machine_number
);

ZK_BOOL ZKEM_CALL Z_GetLog(
    int machine_number,
    int *tmachine,
    int *enroll_number,
    int *emachine_number,
    int *verify_mode,
    int *in_out_mode,
    int *year,
    int *month,
    int *day,
    int *hour,
    int *minute
);

/*
 * Error handling
 */

ZK_BOOL ZKEM_CALL Z_LastError(
    int *error_code
);

enum {
    ZK_SUCCESS           = 1,
    ZK_ERR_NO_DATA       = 0,
    ZK_ERR_INVALID_PARAM = 4,

    ZK_ERROR_NOT_INIT    = -1,
    ZK_ERROR_IO          = -2,
    ZK_ERROR_SIZE        = -3,
    ZK_ERROR_NO_SPACE    = -4,

    ZK_ERROR_UNSUPPORT   = -100,
};

#endif
